// ignore_for_file: unnecessary_new, prefer_interpolation_to_compose_strings

// MPN is not available on windows and macos
@TestOn('!windows && !mac-os')

import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import './utils.dart';

void main() {
  final host = Platform.isAndroid ? "http://10.0.2.2:8080" : "http://127.0.0.1:8080";
  late MpnDevice device;
  late MpnSubscription sub;
  late LightstreamerClient client;
  late BaseDeviceListener devListener;
  late BaseMpnSubscriptionListener subListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  test('MpnSubscription ctors', () {
    var sub = Subscription('MERGE', ['i1', 'i2'], ['f1', 'f2']);
    sub.setDataAdapter('data');
    sub.setRequestedBufferSize('10');
    sub.setRequestedMaxFrequency('0.5');

    var sub1 = MpnSubscription.fromSubscription(sub);
    assertEqual('MERGE', sub1.getMode());
    assertEqual(['i1', 'i2'], sub1.getItems());
    assertEqual(['f1', 'f2'], sub1.getFields());
    assertNull(sub1.getItemGroup());
    assertNull(sub1.getFieldSchema());
    assertEqual('data', sub1.getDataAdapter());
    assertEqual('10', sub1.getRequestedBufferSize());
    assertEqual('0.5', sub1.getRequestedMaxFrequency());
    assertNull(sub1.getTriggerExpression());
    assertNull(sub1.getNotificationFormat());

    sub1.setTriggerExpression('1 < 0');
    sub1.setNotificationFormat('{foo: 123}');

    var sub2 = MpnSubscription.fromMpnSubscription(sub1);
    assertEqual('MERGE', sub2.getMode());
    assertEqual(['i1', 'i2'], sub2.getItems());
    assertEqual(['f1', 'f2'], sub2.getFields());
    assertNull(sub2.getItemGroup());
    assertNull(sub2.getFieldSchema());
    assertEqual('data', sub2.getDataAdapter());
    assertEqual('10', sub2.getRequestedBufferSize());
    assertEqual('0.5', sub2.getRequestedMaxFrequency());
    assertEqual('1 < 0', sub2.getTriggerExpression());
    assertEqual('{foo: 123}', sub2.getNotificationFormat());
  });

  test('MpnSubscription errors', () async {
    client = LightstreamerClient(host, "TEST");
    var sub = new MpnSubscription("MERGE", ["count"], ["count"]);
    sub.setNotificationFormat('{}');
    device = MpnDevice();
    await client.registerForMpn(device);
    client.subscribeMpn(sub, false);
    try {
      await client.subscribeMpn(sub, false);
      fail('Expected PlatformException');
    } on PlatformException catch(e) {
      assertEqual('Lightstreamer Internal Error', e.code);
      assertEqual('Cannot subscribe to an active MpnSubscription', e.message);
    }
    
    await client.unsubscribeMpn(sub);
    sub.setTriggerExpression('0==0');
    await client.subscribeMpn(sub, false);
  });

  test('subscribeToSameObjectTwice', () async {
    var exps = Expectations();
    var client2 = LightstreamerClient(host, "TEST");

    device = MpnDevice();
    devListener = BaseDeviceListener();
    devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
    device.addListener(devListener);

    sub = new MpnSubscription("MERGE", ["count"], ["count"]);
    sub.setDataAdapter("COUNT");
    sub.setNotificationFormat('{"android":{"notification":{"title":"my_title_2"}}}');
    sub.setTriggerExpression('0==0');

    await client2.registerForMpn(device);
    await client2.connect();
    await exps.value('onSubscriptionsUpdated');
    
    client2.subscribeMpn(sub, false);
    await exps.value('onSubscriptionsUpdated');
    var subs = await client2.getMpnSubscriptions();
    assertEqual(1, subs.length);

    client2.unsubscribeMpn(sub);
    await exps.value('onSubscriptionsUpdated');
    subs = await client2.getMpnSubscriptions();
    assertEqual(0, subs.length);

    client2.disconnect();

    client = LightstreamerClient(host, "TEST");
    await client.registerForMpn(device);
    await client.connect();
    await exps.value('onSubscriptionsUpdated');

    client.subscribeMpn(sub, false);
    await exps.value('onSubscriptionsUpdated');
    subs = await client.getMpnSubscriptions();
    assertEqual(1, subs.length);
  });

  if (Platform.isAndroid) {
    test('android builder', () async {
      var builder = new FirebaseMpnBuilder();
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
  } else {
    test('apns builder', () async {
      var builder = new ApnsMpnBuilder();
      var format = await builder
          .setTitle("TITLE")
          .setBody("BODY")
          .setBadge("ICON")
          .setCustomData({"d": "D"})
          .build();
      // expected: {"d":"D","aps":{"badge":"ICON","alert":{"body":"BODY","title":"TITLE"}}}
      // NB since the order of the keys in the json changes from run to run, the comparisons are made piecemeal
      assertTrue(format.contains('"d":"D"'));
      assertTrue(format.contains('"badge":"ICON"'));
      assertTrue(format.contains('"body":"BODY"'));
      assertTrue(format.contains('"title":"TITLE"'));
      assertTrue(format.contains('"aps":'));
      assertEqual({"d": "D"}, builder.getCustomData());
    });
  }

  ["WS-STREAMING", "HTTP-STREAMING", "HTTP-POLLING", "WS-POLLING"].forEach((transport) { 

    group(transport, () {

      setUp(() async {
        client = LightstreamerClient(host, "TEST");
        /* create an Android device */
        device = new MpnDevice();
        devListener = new BaseDeviceListener();
        device.addListener(devListener);
        /* create notification descriptor */
        var descriptor = await buildFormat();
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
        await client.registerForMpn(device);
        await exps.value("onStatusChanged REGISTERED");
        await exps.value("onRegistered");
        assertEqual("REGISTERED", device.getStatus());
        assertTrue(device.isRegistered());
        assertFalse(device.isSuspended());
        assertTrue((device.getStatusTimestamp()) >= 0);
        assertEqual(Platform.isAndroid ? "Google" : "Apple", device.getPlatform());
        assertEqual(Platform.isAndroid ? "com.lightstreamer.push_demo.android.fcm" : "com.lightstreamer.ios.stocklist", device.getApplicationId());
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
        var descriptor = await buildFormat();
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
        if (Platform.isAndroid) {
          sub.setNotificationFormat(await FirebaseMpnBuilder().setTitle("my_title_2").build());
          assertEqual("{\"android\":{\"notification\":{\"title\":\"my_title_2\"}}}", sub.getNotificationFormat());
          await exps.until("format {\"android\":{\"notification\":{\"title\":\"my_title_2\"}}}");
        } else {
          sub.setNotificationFormat(await ApnsMpnBuilder().setTitle("my_title_2").build());
          assertEqual('{"aps":{"alert":{"title":"my_title_2"}}}', sub.getNotificationFormat());
          await exps.until('format {"aps":{"alert":{"title":"my_title_2"}}}');
        }
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
        if (Platform.isAndroid) {
          subCopy.setNotificationFormat(await FirebaseMpnBuilder().setTitle("my_title_2").build());
        } else {
          subCopy.setNotificationFormat(await ApnsMpnBuilder().setTitle("my_title_2").build());
        }
        var subCopyListener = new BaseMpnSubscriptionListener();
        subCopy.addListener(subCopyListener);
        subCopyListener.fSubscription = () => exps.signal("onSubscription copy");
        client.connect();
        await client.registerForMpn(device);
        client.subscribeMpn(sub, false);
        await exps.value("onSubscription");
        client.subscribeMpn(subCopy, true);
        await exps.until("onSubscription copy");
        if (Platform.isAndroid) {
          await exps.until('format {"android":{"notification":{"title":"my_title_2"}}}');
          assertEqual('{"android":{"notification":{"icon":"my_icon","title":"my_title","body":"my_body"}}}', sub.getNotificationFormat());
        } else {
          await exps.until('format {"aps":{"alert":{"title":"my_title_2"}}}');
          assertEqual('{"aps":{"alert":{"title":"my_title"}}}', sub.getNotificationFormat());
        }

        assertEqual(sub.getSubscriptionId(), subCopy.getSubscriptionId());
        assertEqual(1, (await client.getMpnSubscriptions("ALL")).length);
        var ss = await client.findMpnSubscription(sub.getSubscriptionId()!);
        assertTrue(ss == sub || ss == subCopy);
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

      test('serverSubscription', () async {
        var exps = new Expectations();
        var dev2 = MpnDevice();
        var client2 = LightstreamerClient(host, "TEST");
        subListener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        client2.connect();
        await client2.registerForMpn(dev2);
        sub.setTriggerExpression("0==0");
        client2.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onStatusChanged TRIGGERED");
        client2.disconnect();

        client.connect();
        devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
        await client.registerForMpn(device);

        await exps.value("onSubscriptionsUpdated");
        var subs = await client.getMpnSubscriptions();
        assertEqual(1, subs.length);
        var s0 = subs[0];
        assertEqual('MERGE', s0.getMode());
        assertEqual('COUNT', s0.getDataAdapter());
        assertEqual('count', s0.getItemGroup());
        assertEqual('count', s0.getFieldSchema());
        if (Platform.isAndroid) {
          assertEqual('{"android":{"notification":{"icon":"my_icon","title":"my_title","body":"my_body"}}}', s0.getActualNotificationFormat());
        } else {
          assertEqual('{"aps":{"alert":{"title":"my_title"}}}', s0.getActualNotificationFormat());
        }
        assertEqual('0==0', s0.getActualTriggerExpression());
        assertEqual('TRIGGERED', s0.getStatus());
        assertEqual(sub.getSubscriptionId(), s0.getSubscriptionId());
        assertTrue(s0.getStatusTimestamp() > 0);
      });

      test('serverSubscriptionNotification', () async {
        var exps = new Expectations();
        var dev2 = MpnDevice();
        var client2 = LightstreamerClient(host, "TEST");
        subListener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        client2.connect();
        await client2.registerForMpn(dev2);
        client2.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        client2.disconnect();

        client.connect();
        devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
        await client.registerForMpn(device);

        await exps.value("onSubscriptionsUpdated");
        var subs = await client.getMpnSubscriptions();
        assertEqual(1, subs.length);

        var s0 = subs[0];
        var s0Listener = BaseMpnSubscriptionListener();
        s0Listener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        s0.addListener(s0Listener);
        s0.setTriggerExpression('0==0');
        await exps.value("onStatusChanged TRIGGERED");
      });

      test('serverSubscriptionUnsubscription', () async {
        var exps = new Expectations();
        var dev2 = MpnDevice();
        var client2 = LightstreamerClient(host, "TEST");
        subListener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        client2.connect();
        await client2.registerForMpn(dev2);
        client2.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        client2.disconnect();

        client.connect();
        devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
        await client.registerForMpn(device);

        await exps.value("onSubscriptionsUpdated");
        var subs = await client.getMpnSubscriptions();
        assertEqual(1, subs.length);
        
        var s0 = subs[0];
        var s0Listener = BaseMpnSubscriptionListener();
        s0Listener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        s0.addListener(s0Listener);
        client.unsubscribeMpn(s0);
        await exps.value("onStatusChanged UNKNOWN");

        await exps.value("onSubscriptionsUpdated");
        subs = await client.getMpnSubscriptions();
        assertEqual(0, subs.length);
      });

      test('findMpnSubscription_found', () async {
        var exps = new Expectations();
        var dev2 = MpnDevice();
        var client2 = LightstreamerClient(host, "TEST");
        subListener.fStatusChanged = (status, ts) => exps.signal('onStatusChanged $status');
        client2.connect();
        await client2.registerForMpn(dev2);
        sub.setTriggerExpression("0==0");
        client2.subscribeMpn(sub, false);
        await exps.value("onStatusChanged ACTIVE");
        await exps.value("onStatusChanged SUBSCRIBED");
        await exps.value("onStatusChanged TRIGGERED");
        client2.disconnect();

        client.connect();
        devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
        await client.registerForMpn(device);

        await exps.value("onSubscriptionsUpdated");
        MpnSubscription? s0_ = await client.findMpnSubscription(sub.getSubscriptionId()!);
        assertNotNull(s0_);
        MpnSubscription s0 = s0_!;
        assertEqual('MERGE', s0.getMode());
        assertEqual('COUNT', s0.getDataAdapter());
        assertEqual('count', s0.getItemGroup());
        assertEqual('count', s0.getFieldSchema());
        if (Platform.isAndroid) {
          assertEqual('{"android":{"notification":{"icon":"my_icon","title":"my_title","body":"my_body"}}}', s0.getActualNotificationFormat());
        } else {
          assertEqual('{"aps":{"alert":{"title":"my_title"}}}', s0.getActualNotificationFormat());
        }
        assertEqual('0==0', s0.getActualTriggerExpression());
        assertEqual('TRIGGERED', s0.getStatus());
        assertEqual(sub.getSubscriptionId(), s0.getSubscriptionId());
        assertTrue(s0.getStatusTimestamp() > 0);
      });

      test('findMpnSubscription_notFound', () async {
        var exps = new Expectations();
        devListener.fSubscriptionsUpdated = () => exps.signal('onSubscriptionsUpdated');
        client.connect();
        client.registerForMpn(device);
        await exps.value("onSubscriptionsUpdated");

        MpnSubscription? s0 = await client.findMpnSubscription('');
        assertNull(s0);
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
       * Verifies that the client unsubscribes from all the subscribed items.
       */
      test('unsubscribe filter subscribed', () async {
        var exps = new Expectations();
        var descriptor = await buildFormat();

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
        var descriptor = await buildFormat();

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
        var descriptor = await buildFormat();

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
        var descriptor = await buildFormat();

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
        var descriptor = await buildFormat();

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
        var descriptor = await buildFormat();

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
        await exps.value("onSubscriptionError 55 The request was discarded because the operation could not be completed");

        client.disconnect();
      });

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
} // main

Future<String> buildFormat() async {
  if (Platform.isAndroid) {
    return await FirebaseMpnBuilder()
            .setTitle("my_title")
            .setBody("my_body")
            .setIcon("my_icon")
            .build();
  } else {
    return await ApnsMpnBuilder()
            .setTitle("my_title")
            .build();
  }
}