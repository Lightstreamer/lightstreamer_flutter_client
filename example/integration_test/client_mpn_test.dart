// ignore_for_file: unnecessary_new, prefer_interpolation_to_compose_strings

import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import './utils.dart';

void main() {
  const host = "http://10.0.2.2:8080";
  late MpnDevice device;
  late MpnSubscription sub;
  late LightstreamerClient client;
  late BaseDeviceListener devListener;
  late BaseMpnSubscriptionListener subListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  ["WS-STREAMING", "HTTP-STREAMING", "HTTP-POLLING", "WS-POLLING"].forEach((transport) { 

    group(transport, () {

      setUp(() async {
        client = await LightstreamerClient.create(host, "TEST");
        /* create an Android device */
        device = new MpnDevice();
        devListener = new BaseDeviceListener();
        device.addListener(devListener);
        /* create notification descriptor */
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();
        /* create MPN subscription */
        sub = new MpnSubscription("MERGE");
        sub.setDataAdapter("COUNT");
        sub.setItemGroup("count");
        sub.setFieldSchema("count");
        sub.setNotificationFormat(descriptor);
        subListener = new BaseMpnSubscriptionListener();
        sub.addListener(subListener);

        client.connectionOptions.setForcedTransport(transport);
        if (transport.endsWith("POLLING")) {
          client.connectionOptions.setIdleTimeout(0);
          client.connectionOptions.setPollingInterval(100);
        }
      });

      Future<void> _cleanup() async {
        var exps = new Expectations();
        if ((await client.getStatus()) != "DISCONNECTED" &&
            (await client.getMpnSubscriptions(null)).isNotEmpty) {
          devListener.fSubscriptionsUpdated = () async => exps.signal(
              "onSubscriptionsUpdated ${(await client.getMpnSubscriptions(null)).length}");
          client.unsubscribeMpnSubscriptions("ALL");
          return exps.until("onSubscriptionsUpdated 0");
        } else {
          return Future.value();
        }
      }

      tearDown(() async {
        var exps = new Expectations();
        await _cleanup();
        devListener.fStatusChanged = (status, ts) => exps.signal("onStatusChanged " + status);
        if ((await client.getStatus()) != "DISCONNECTED") {
          client.disconnect();
          await exps.until("onStatusChanged UNKNOWN");
        }
      });

      test('listeners', () async {
        var exps = new Expectations();
        var ls = device.getListeners();
        assertEqual(1, ls.length);
        assertEqual(true, devListener == ls[0]);

        var cl2 = BaseDeviceListener();
        cl2.fListenStart = () => exps.signal('MpnDeviceListener.onListenStart');
        cl2.fListenEnd = () => exps.signal('MpnDeviceListener.onListenEnd');
        device.addListener(cl2);
        await exps.value('MpnDeviceListener.onListenStart');
        device.removeListener(cl2);
        await exps.value('MpnDeviceListener.onListenEnd');

        var sub = new MpnSubscription("MERGE", ["count"], ["count"]);
        sub.addListener(subListener);
        var subls = sub.getListeners();
        assertEqual(1, subls.length);
        assertEqual(true, subListener == subls[0]);

        var sl2 = BaseMpnSubscriptionListener();
        sl2.fListenStart = () => exps.signal('MpnSubscriptionListener.onListenStart');
        sl2.fListenEnd = () => exps.signal('MpnSubscriptionListener.onListenEnd');
        sub.addListener(sl2);
        await exps.value('MpnSubscriptionListener.onListenStart');
        sub.removeListener(sl2);
        await exps.value('MpnSubscriptionListener.onListenEnd');
      });

      /**
       * Verifies that the client registers to the MPN module.
       */
      test('register', () async {
        var exps = new Expectations();
        devListener.fRegistered = () => exps.signal("onRegistered");
        devListener.fStatusChanged =
            (status, ts) => exps.signal("onStatusChanged " + status);
        client.connect();
        client.registerForMpn(device);
        await exps.value("onStatusChanged REGISTERED");
        await exps.value("onRegistered");
        assertEqual("REGISTERED", device.getStatus());
        assertTrue(device.isRegistered());
        assertFalse(device.isSuspended());
        assertTrue((device.getStatusTimestamp()) >= 0);
        assertEqual("Google", device.getPlatform());
        assertEqual("com.lightstreamer.push_demo.android.fcm", device.getApplicationId());
        assertNotNull(device.getDeviceId());
        assertNotNull(device.getDeviceToken());
      });

      /**
       * Verifies that when the registration fails the device listener is notified.
       */
      test('register error', () async {
        var exps = new Expectations();
        device = new MpnDevice();
        devListener = new BaseDeviceListener();
        device.addListener(devListener);
        devListener.fRegistrationFailed =
            (code, msg) => exps.signal('onRegistrationFailed $code $msg');
        client.connect();
        client.registerForMpn(device);
        await exps.value("onRegistrationFailed 43 MPN invalid application ID");
      }, skip: "Can't simulate this kind of scenario because an invalid application ID can't be injected here");

      /**
       * Verifies that the client subscribes to an MPN item.
       */
      test('subscribe', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fSubscription = () => exps.signal("onSubscription");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onSubscription");
        assertTrue(sub.isActive());
        assertTrue(sub.isSubscribed());
        assertFalse(sub.isTriggered());
        assertEqual("SUBSCRIBED", sub.getStatus());
        assertTrue(sub.getStatusTimestamp() >= 0);
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();
        var expectedFormat = descriptor;
        var actualFormat = sub.getNotificationFormat();
        assertEqual(expectedFormat, actualFormat);
        assertNull(sub.getTriggerExpression());
        assertEqual("COUNT", sub.getDataAdapter());
        assertNull(sub.getRequestedBufferSize());
        assertNull(sub.getRequestedMaxFrequency());
        assertEqual("MERGE", sub.getMode());
        assertEqual("count", sub.getItemGroup());
        assertEqual("count", sub.getFieldSchema());
        assertNotNull(sub.getSubscriptionId());
      });

      /**
       * Verifies that, when the client modifies an active subscription, the changes
       * are propagated back to the subscription.
       * <p>
       * The following scenario is exercised:
       * <ul>
       * <li>the client subscribes to an item</li>
       * <li>the changes are propagated back to the original subscription</li>
       * </ul>
       */
      test('subscribe modify', () async {
        var exps = new Expectations();
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fPropertyChanged = (prop) {
          switch (prop) {
            case "trigger":
              exps.signal("trigger ${sub.getActualTriggerExpression()}");
            case "notification_format":
              exps.signal("format ${sub.getActualNotificationFormat()}");
          }
        };
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onSubscription");
        assertNull(sub.getActualTriggerExpression());
        assertNull(sub.getActualNotificationFormat());

        sub.setTriggerExpression("0<1");
        assertEqual("0<1", sub.getTriggerExpression());
        await exps.until("trigger 0<1");
        sub.setNotificationFormat(
            await AndroidMpnBuilder().setTitle("my_title_2").build());
        assertEqual("{\"android\":{\"notification\":{\"title\":\"my_title_2\"}}}",
            sub.getNotificationFormat());
        await exps.until(
            "format {\"android\":{\"notification\":{\"title\":\"my_title_2\"}}}");
      });

      /**
       * Verifies that, when the client modifies a TRIGGERED subscription, the state changes to SUBSCRIBED.
       */
      test('subscribe modify reactivate', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, _) => exps.signal("onStatusChanged " + status);
        client.connect();
        await client.registerForMpn(device);
        sub.setTriggerExpression("true"); // so we are sure that the item becomes triggered
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onStatusChanged TRIGGERED");
        // assertEqual("true", sub.getActualTriggerExpression());

        sub.setTriggerExpression("false");
        await exps.value("onStatusChanged SUBSCRIBED");
        // assertEqual("false", sub.getActualTriggerExpression());
      });

      /**
       * Verifies that, when the client overrides an active subscription using the coalescing option, the changes
       * are propagated back to the subscription.
       * <p>
       * The following scenario is exercised:
       * <ul>
       * <li>the client subscribes to an item</li>
       * <li>the client creates a copy of the subscription</li>
       * <li>the client modifies a few parameters of the copy</li>
       * <li>the client subscribes using the copy specifying the coalescing option</li>
       * <li>the changes are propagated back to the original subscription</li>
       * </ul>
       */
      test('subscribe modify coalesce', () async {
        var exps = new Expectations();
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fPropertyChanged = (prop) {
          switch (prop) {
            case "notification_format":
              exps.signal("format ${sub.getActualNotificationFormat()}");
          }
        };
        var subCopy = new MpnSubscription("MERGE");
        subCopy.setDataAdapter("COUNT");
        subCopy.setItemGroup("count");
        subCopy.setFieldSchema("count");
        subCopy.setNotificationFormat(
            await AndroidMpnBuilder().setTitle("my_title_2").build());
        var subCopyListener = new BaseMpnSubscriptionListener();
        subCopy.addListener(subCopyListener);
        subCopyListener.fSubscription = () => exps.signal("onSubscription copy");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onSubscription");
        client.subscribeMpn(subCopy, true);
        await exps.until("onSubscription copy");
        await exps.until('format {"android":{"notification":{"title":"my_title_2"}}}');
        assertEqual(
            '{"android":{"notification":{"icon":"my_icon","title":"my_title","body":"my_body"}}}',
            sub.getNotificationFormat());

        assertEqual(sub.getSubscriptionId(), subCopy.getSubscriptionId());
        assertEqual(1, (await client.getMpnSubscriptions("ALL")).length);
        assertTrue(sub == await client.findMpnSubscription(sub.getSubscriptionId()!));
      });

      /**
       * Verifies that, when the subscription fails, the subscription listener is notified.
       */
      test('subscribe error', () async {
        var exps = new Expectations();
        sub.setDataAdapter("unknown.adapter");
        subListener.fSubscriptionError =
            (code, msg) => exps.signal('onSubscriptionError $code $msg');
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onSubscriptionError 17 Data Adapter not found");
      });

      /**
       * Verifies that the client unsubscribes from an MPN item.
       */
      test('unsubscribe', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fUnsubscription = () => exps.signal("onUnsubscription");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onSubscription");
        assertEqual("SUBSCRIBED", sub.getStatus());
        client.unsubscribeMpn(sub);
        await exps.value("onStatusChanged UNKNOWN");
        await exps.value("onUnsubscription");
        assertEqual("UNKNOWN", sub.getStatus());
      });

      /**
       * Verifies that the client doesn't send a subscription request if an unsubscription request follows immediately.
       */
      test('fast unsubscription', () async {
        var exps = new Expectations();
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fUnsubscription = () => exps.signal("onUnsubscription");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        client.unsubscribeMpn(sub);
        // await exps.value("onSubscription");
        // await exps.value("onUnsubscription");
        // must not fire any listeners
      }, skip: "Can't simulate this kind of scenario: subscription operations are not fast enough to trigger the desired behavior");

      /**
       * Verifies that the client unsubscribes from all the subscribed items.
       */
      test('unsubscribe filter subscribed', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        var sub1Listener = new BaseMpnSubscriptionListener();
        sub1.addListener(sub1Listener);
        sub1Listener.fSubscription = () => exps.signal("onSubscription sub1");
        sub1Listener.fUnsubscription = () => exps.signal("onUnsubscription sub1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        // this expression is always true because the counter is >= 0
        sub2.setTriggerExpression("Integer.parseInt(\${count}) > -1");
        var sub2Listener = new BaseMpnSubscriptionListener();
        sub2.addListener(sub2Listener);
        sub2Listener.fTriggered = () => exps.signal("onTriggered sub2");
        sub2Listener.fUnsubscription = () => exps.signal("onUnsubscription sub2");

        await client.registerForMpn(device);
        client.subscribeMpn(sub1, false);
        client.connect();
        await exps.value("onSubscription sub1");
        client.subscribeMpn(sub2, false);
        await exps.value("onTriggered sub2");
        var subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(1, subscribedLs.length);
        assertEqual(sub1, subscribedLs[0]);

        var triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(1, triggeredLs.length);
        assertEqual(sub2, triggeredLs[0]);

        var allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(2, allLs.length);

        client.unsubscribeMpnSubscriptions("SUBSCRIBED");
        await exps.value("onUnsubscription sub1");
        subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(0, subscribedLs.length);

        triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(1, triggeredLs.length);
        assertEqual(sub2, triggeredLs[0]);

        allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(1, allLs.length);
        assertEqual(sub2, allLs[0]);

        client.unsubscribeMpnSubscriptions(null);
        await exps.value("onUnsubscription sub2");
        assertEqual(0, (await client.getMpnSubscriptions("ALL")).length);
      });

      /**
       * Verifies that the client unsubscribes from all the triggered items.
       */
      test('unsubscribe filter triggered', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        var sub1Listener = new BaseMpnSubscriptionListener();
        sub1.addListener(sub1Listener);
        sub1Listener.fSubscription = () => exps.signal("onSubscription sub1");
        sub1Listener.fUnsubscription = () => exps.signal("onUnsubscription sub1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        // this expression is always true because the counter is >= 0
        sub2.setTriggerExpression("Integer.parseInt(\${count}) > -1");
        var sub2Listener = new BaseMpnSubscriptionListener();
        sub2.addListener(sub2Listener);
        sub2Listener.fTriggered = () => exps.signal("onTriggered sub2");
        sub2Listener.fUnsubscription = () => exps.signal("onUnsubscription sub2");

        await client.registerForMpn(device);
        client.subscribeMpn(sub1, false);
        client.connect();
        await exps.value("onSubscription sub1");
        client.subscribeMpn(sub2, false);
        await exps.value("onTriggered sub2");

        var subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(1, subscribedLs.length);
        assertEqual(sub1, subscribedLs[0]);

        var triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(1, triggeredLs.length);
        assertEqual(sub2, triggeredLs[0]);

        var allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(2, allLs.length);

        client.unsubscribeMpnSubscriptions("TRIGGERED");
        await exps.value("onUnsubscription sub2");
        subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(1, subscribedLs.length);
        assertEqual(sub1, subscribedLs[0]);

        triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(0, triggeredLs.length);

        allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(1, allLs.length);
        assertEqual(sub1, allLs[0]);

        client.unsubscribeMpnSubscriptions(null);
        await exps.value("onUnsubscription sub1");
        assertEqual(0, (await client.getMpnSubscriptions("ALL")).length);
      });

      /**
       * Verifies that the client unsubscribes from all the triggered items.
       */
      test('unsubscribe filter all', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        var sub1Listener = new BaseMpnSubscriptionListener();
        sub1.addListener(sub1Listener);
        sub1Listener.fSubscription = () => exps.signal("onSubscription sub1");
        sub1Listener.fUnsubscription = () => exps.signal("onUnsubscription sub1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        // this expression is always true because the counter is >= 0
        sub2.setTriggerExpression("Integer.parseInt(\${count}) > -1");
        var sub2Listener = new BaseMpnSubscriptionListener();
        sub2.addListener(sub2Listener);
        sub2Listener.fTriggered = () => exps.signal("onTriggered sub2");
        sub2Listener.fUnsubscription = () => exps.signal("onUnsubscription sub2");

        await client.registerForMpn(device);
        client.subscribeMpn(sub1, false);
        client.connect();
        await exps.value("onSubscription sub1");
        client.subscribeMpn(sub2, false);
        await exps.value("onTriggered sub2");

        var subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(1, subscribedLs.length);
        assertEqual(sub1, subscribedLs[0]);

        var triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(1, triggeredLs.length);
        assertEqual(sub2, triggeredLs[0]);

        var allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(2, allLs.length);

        client.unsubscribeMpnSubscriptions("ALL");
        await exps.value("onUnsubscription sub1");
        await exps.value("onUnsubscription sub2");
        subscribedLs = await client.getMpnSubscriptions("SUBSCRIBED");
        assertEqual(0, subscribedLs.length);

        triggeredLs = await client.getMpnSubscriptions("TRIGGERED");
        assertEqual(0, triggeredLs.length);

        allLs = await client.getMpnSubscriptions("ALL");
        assertEqual(0, allLs.length);
      });

      /**
       * Verifies that a subscription can start in state TRIGGERED.
       */
      test('trigger 1', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fTriggered = () => exps.signal("onTriggered");
        client.connect();
        await client.registerForMpn(device);
        // this expression is always true because the counter is >= 0
        sub.setTriggerExpression("Integer.parseInt(\${count}) > -1");
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onStatusChanged TRIGGERED");
        await exps.value("onTriggered");
        assertTrue(sub.isTriggered());
        assertEqual("TRIGGERED", sub.getStatus());
        assertTrue(sub.getStatusTimestamp() > 0);
      });

      /**
       * Verifies that, when the triggering condition holds, the subscription becomes TRIGGERED.
       * <p>
       * The following scenario is exercised:
       * <ul>
       * <li>the client subscribes to an item</li>
       * <li>the client modifies the subscription adding a trigger</li>
       * <li>the trigger fires on the server</li>
       * <li>the client method onTriggered is notified</li>
       * </ul>
       */
      test('trigger 2', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fTriggered = () => exps.signal("onTriggered");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onSubscription");
        // this expression is always true because the counter is >= 0
        sub.setTriggerExpression("Integer.parseInt(\${count}) > -1");
        await exps.value("onStatusChanged TRIGGERED");
        await exps.value("onTriggered");
        assertTrue(sub.isTriggered());
        assertEqual("TRIGGERED", sub.getStatus());
        assertTrue(sub.getStatusTimestamp() > 0);
      });

      /**
       * Verifies that the two subscription objects become subscribed.
       */
      test('double subscription', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        var sub1Listener = new BaseMpnSubscriptionListener();
        sub1.addListener(sub1Listener);
        sub1Listener.fSubscription = () => exps.signal("onSubscription sub1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        var sub2Listener = new BaseMpnSubscriptionListener();
        sub2.addListener(sub2Listener);
        sub2Listener.fSubscription = () => exps.signal("onSubscription sub2");

        await client.registerForMpn(device);
        client.connect();
        client.subscribeMpn(sub1, false);
        await exps.value("onSubscription sub1");
        client.subscribeMpn(sub2, false);
        await exps.value("onSubscription sub2");
        assertEqual(2, (await client.getMpnSubscriptions(null)).length);
        assertFalse(sub1.getSubscriptionId() == sub2.getSubscriptionId());
      });

      /**
       * Verifies that the MPN subscriptions are preserved upon disconnection.
       * <p>
       * The scenario exercised is the following:
       * <ul>
       * <li>the client subscribes to two items</li>
       * <li>the client disconnects</li>
       * <li>the client reconnects</li>
       * <li>the server sends to the client the data about the two subscriptions</li>
       * </ul>
       */
      test('double subscription disconnect', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        devListener.fSubscriptionsUpdated = () async => exps.signal(
            "onSubscriptionsUpdated ${(await client.getMpnSubscriptions("SUBSCRIBED")).length}");
        /*
        * NB the following trigger conditions are always false because
        * the counter value is always bigger than zero.
        */
        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        sub1.setTriggerExpression("Integer.parseInt(\${count}) < -1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        sub2.setTriggerExpression("Integer.parseInt(\${count}) < -2");

        await client.registerForMpn(device);
        client.connect();

        await exps.value("onSubscriptionsUpdated 0");
        client.subscribeMpn(sub1, false);
        await exps.value("onSubscriptionsUpdated 1");
        client.subscribeMpn(sub2, false);
        await exps.value("onSubscriptionsUpdated 2");

        client.disconnect();
        client.connect();
        await exps.value("onSubscriptionsUpdated 2");
        assertFalse(sub1.getSubscriptionId() == sub2.getSubscriptionId());
      });

    test('status change', () async {
        var exps = new Expectations();
        subListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        client.connect();
        await client.registerForMpn(device);
        assertEqual("UNKNOWN", sub.getStatus());
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        assertEqual("ACTIVE", sub.getStatus());
        await exps.value("onStatusChanged SUBSCRIBED");
        assertEqual("SUBSCRIBED", sub.getStatus());

        client.unsubscribeMpn(sub);
        await exps.value("onStatusChanged UNKNOWN");
        assertEqual("UNKNOWN", sub.getStatus());
      });

      /**
       * Verifies that {@code onSubscriptionsUpdated} is notified even if the snapshot doesn't contain any subscriptions.
       * <p>
       * The following scenario is exercised:
       * <ul>
       * <li>the client registers to MPN module</li>
       * <li>SUBS adapter publishes an empty snapshot</li>
       * <li>{@code onSubscriptionsUpdated} is fired</li>
       * </ul>
       */
      test('onSubscriptionsUpdated empty', () async {
        var exps = new Expectations();
        devListener.fSubscriptionsUpdated =
            () => exps.signal("onSubscriptionsUpdated");
        client.connect();
        client.registerForMpn(device);
        await exps.value("onSubscriptionsUpdated");
        assertEqual(0, (await client.getMpnSubscriptions("ALL")).length);
      });

      /**
       * Verifies that {@code onSubscriptionsUpdated} is notified when the cached subscriptions change.
       * <p>
       * The following scenario is exercised:
       * <ul>
       * <li>the client subscribes to two MPN items</li>
       * <li>when MPNOK is received, {@code onSubscriptionsUpdated} is fired</li>
       * <li>the client disconnects</li>
       * <li>the client reconnects</li>
       * <li>when SUBS adapter publishes the two previous MPN items, {@code onSubscriptionsUpdated} is fired</li>
       * <li>the client unsubscribes from the two items</li>
       * <li>when DELETE is received, {@code onSubscriptionsUpdated} is fired</li>
       * </ul>
       */
      test('onSubscriptionsUpdated', () async {
        var exps = new Expectations();
        var descriptor = await AndroidMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();

        devListener.fSubscriptionsUpdated = () async => exps.signal(
            "onSubscriptionsUpdated ${(await client.getMpnSubscriptions("ALL")).length}");
        /*
        * NB the following trigger conditions are always false because
        * the counter value is always bigger than zero.
        */
        var sub1 = new MpnSubscription("MERGE");
        sub1.setDataAdapter("COUNT");
        sub1.setItemGroup("count");
        sub1.setFieldSchema("count");
        sub1.setNotificationFormat(descriptor);
        sub1.setTriggerExpression("Integer.parseInt(\${count}) < -1");

        var sub2 = new MpnSubscription("MERGE");
        sub2.setDataAdapter("COUNT");
        sub2.setItemGroup("count");
        sub2.setFieldSchema("count");
        sub2.setNotificationFormat(descriptor);
        sub2.setTriggerExpression("Integer.parseInt(\${count}) < -2");

        client.registerForMpn(device);
        client.connect();
        await exps.value("onSubscriptionsUpdated 0");
        client.subscribeMpn(sub1, false);
        await exps.value("onSubscriptionsUpdated 1");
        client.subscribeMpn(sub2, false);
        await exps.value("onSubscriptionsUpdated 2");

        client.disconnect();
        client.connect();
        await exps.value("onSubscriptionsUpdated 2");
        client.unsubscribeMpn(sub1);
        await exps.value("onSubscriptionsUpdated 1");
        client.unsubscribeMpn(sub2);
        await exps.value("onSubscriptionsUpdated 0");
      });

    test('unsubscribe error', () async {
        var exps = new Expectations();
        subListener.fSubscriptionError =
            (code, msg) => exps.signal('onSubscriptionError $code $msg');
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        client.unsubscribeMpn(sub);
        await exps.value(
            "onSubscriptionError 55 The request was discarded because the operation could not be completed");
      }, skip: "Can't simulate this kind of scenario: subscription operations are not fast enough to trigger the desired behavior");

      test('set trigger error', () async {
        var exps = new Expectations();
        devListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fModificationError = (code, msg, prop) =>
            exps.signal('onModificationError $code $msg ($prop)');
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged REGISTERED");
        await exps.value("onSubscription");
        sub.setTriggerExpression("1==2");
        client.disconnect();
        await exps.value("onStatusChanged UNKNOWN");
        await exps.value(
            "onModificationError 54 The request was aborted because the operation could not be completed (trigger)");

        client.connect();
        await exps.value("onStatusChanged REGISTERED");
      });

      test('set notification error', () async {
        var exps = new Expectations();
        devListener.fStatusChanged =
            (status, ts) => exps.signal('onStatusChanged $status');
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fModificationError = (code, msg, prop) =>
            exps.signal('onModificationError $code $msg ($prop)');
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onStatusChanged REGISTERED");
        await exps.value("onSubscription");
        sub.setNotificationFormat("{}");
        client.disconnect();
        await exps.value("onStatusChanged UNKNOWN");
        await exps.value(
            "onModificationError 54 The request was aborted because the operation could not be completed (notification_format)");
        client.connect();
        await exps.value("onStatusChanged REGISTERED");
      });

    }); // group
  }); // for each group

  test('android builder', () async {
    var builder = new AndroidMpnBuilder();
    var format = await builder
        .setTitle("TITLE")
        .setBody("BODY")
        .setIcon("ICON")
        .setData({"d": "D"})
        .build();
    assertEqual(
        '{"android":{"notification":{"icon":"ICON","title":"TITLE","body":"BODY"},"data":{"d":"D"}}}',
        format);
    assertEqual({"d": "D"}, builder.getData());
  });
}
