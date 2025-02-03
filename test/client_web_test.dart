import 'package:test/test.dart';
import 'package:js/js_util.dart' as js;
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';
import './utils.dart';

void main() {
  late Expectations exps;
  late LightstreamerClient client;
  late BaseClientListener listener;
  late BaseSubscriptionListener subListener;
  late BaseMessageListener msgListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  ["WS-STREAMING", "HTTP-STREAMING", "HTTP-POLLING", "WS-POLLING"].forEach((transport) { 

    group(transport, () {

      setUp(() {
        exps = new Expectations();
        client = new LightstreamerClient("http://localhost:8080", "TEST");
        listener = new BaseClientListener();
        subListener = new BaseSubscriptionListener();
        msgListener = new BaseMessageListener();
        client.addListener(listener);

        client.connectionOptions.setForcedTransport(transport);
        if (transport.endsWith("POLLING")) {
          client.connectionOptions.setIdleTimeout(0);
          client.connectionOptions.setPollingInterval(100);
        }
      });

      tearDown(() {
        client.disconnect();
      });

      test('listeners', () {
        var ls = client.getListeners();
        assertEqual(1, ls.length);
        assertEqual(true, listener == ls[0]);

        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.addListener(subListener);
        var subls = sub.getListeners();
        assertEqual(1, subls.length);
        assertEqual(true, subListener == subls[0]);
      });

      test('connect', () async {
        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual(expected, client.getStatus());
      });

      test('online server', () async {
        client.connectionDetails.setServerAddress("https://push.lightstreamer.com");
        client.connectionDetails.setAdapterSet("DEMO");
        listener = new BaseClientListener();
        client.addListener(listener);

        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual(expected, client.getStatus());
      });

      test('error', () async {
        client = new LightstreamerClient("http://localhost:8080", "XXX");
        listener = new BaseClientListener();
        client.addListener(listener);
        listener.fServerError = (code, msg) {
          exps.signal('$code $msg');
        };
        client.connect();
        await exps.value("2 Requested Adapter Set not available");
      });

      test('disconnect', () async {
        listener.fStatusChange = (status) {
          if (status == "CONNECTED:" + transport) {
            client.disconnect();
          } else if (status == "DISCONNECTED") {
            exps.signal();
          }
        };
        client.connect();
        await exps.value();
        assertEqual("DISCONNECTED", client.getStatus());
      });

      test('subscribe', () async {
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        var subs = client.getSubscriptions();
        assertEqual(1, subs.length);
        assertEqual(true, sub == subs[0]);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
      });

      test('subscription error', () async {
        var sub = new Subscription("RAW", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscriptionError = (code, msg) {
          exps.signal('$code $msg');
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("24 Invalid mode for these items");
      });

      test('subscribe command', () async {
        var sub = new Subscription("COMMAND", ["mult_table"], ["key", "value1", "value2", "command"]);
        sub.setDataAdapter("MULT_TABLE");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
        assertEqual(1, sub.getKeyPosition());
        assertEqual(4, sub.getCommandPosition());
      });

      test('subscribe command 2 levels', () async {
        var sub = new Subscription("COMMAND", ["two_level_command_count" + transport], ["key", "command"]);
        sub.setDataAdapter("TWO_LEVEL_COMMAND");
        sub.setCommandSecondLevelDataAdapter("COUNT");
        sub.setCommandSecondLevelFields(["count"]);
        sub.addListener(subListener);
        var regex = new RegExp('\\d+');
        subListener.fItemUpdate = (update) {
          var val = update.getValue("count") ?? "";
          var key = update.getValue("key") ?? "";
          var cmd = update.getValue("command") ?? "";
          if (regex.hasMatch(val) && key == "count" && cmd == "UPDATE") {
            exps.signal();
          }
        };
        client.subscribe(sub);
        var subs = client.getSubscriptions();
        assertEqual(1, subs.length);
        assertEqual(true, sub == subs[0]);
        client.connect();
        await exps.value();
        assertEqual(true, sub.isSubscribed());
        assertEqual(1, sub.getKeyPosition());
        assertEqual(2, sub.getCommandPosition());
      });

      test('unsubscribe', () async {
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          client.unsubscribe(sub);
        };
        subListener.fUnsubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        client.connect();
        await exps.value();
        assertEqual(false, sub.isSubscribed());
        assertEqual(false, sub.isActive());
      });

      test('subscribe non-ascii', () async {
        var sub = new Subscription("MERGE", ["strange:àìùòlè"], ["value🌐-", "value&+=\r\n%"]);
        sub.setDataAdapter("STRANGE_NAMES");
        sub.addListener(subListener);
        subListener.fSubscription = () {
          exps.signal();
        };
        client.subscribe(sub);
        client.connect();
        await exps.value();
      });

      test('bandwidth', () async {
        listener.fPropertyChange = (prop) {
          switch (prop) {
            case "realMaxBandwidth":
              exps.signal("realMaxBandwidth=" + (client.connectionOptions.getRealMaxBandwidth() ?? ""));
          }
        };
        assertEqual("unlimited", client.connectionOptions.getRequestedMaxBandwidth());
        client.connect();
        await exps.value("realMaxBandwidth=40"); // after the connection, the server sends the default bandwidth
        // request a bandwidth equal to 20.1: the request is accepted
        client.connectionOptions.setRequestedMaxBandwidth("20.1");
        await exps.value("realMaxBandwidth=20.1");
        // request a bandwidth equal to 70.1: the meta-data adapter cuts it to 40 (which is the configured limit)
        client.connectionOptions.setRequestedMaxBandwidth("70.1");
        await exps.value("realMaxBandwidth=40");
        // request an unlimited bandwidth: the meta-data adapter cuts it to 40 (which is the configured limit)
        client.connectionOptions.setRequestedMaxBandwidth("unlimited");
        // NB the listener isn't notified again because the value isn't changed
        // await exps.value("realMaxBandwidth=40");
      });

      test('clear snapshot', () async {
        var sub = new Subscription("DISTINCT", ["clear_snapshot"], ["dummy"]);
        sub.setDataAdapter("CLEAR_SNAPSHOT");
        sub.addListener(subListener);
        subListener.fClearSnapshot = (name, pos) {
          exps.signal('$name $pos');
        };
        client.subscribe(sub);
        client.connect();
        await exps.value('clear_snapshot 1');
      });

      test('roundtrip', () async {
        assertEqual("TEST", client.connectionDetails.getAdapterSet());
        assertEqual("http://localhost:8080", client.connectionDetails.getServerAddress());
        assertEqual(50000000, client.connectionOptions.getContentLength());
        assertEqual(4000, client.connectionOptions.getRetryDelay());
        assertEqual(15000, client.connectionOptions.getSessionRecoveryTimeout());
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        assertEqual("COUNT", sub.getDataAdapter());
        assertEqual("MERGE", sub.getMode());
        sub.addListener(subListener);
        subListener.fSubscription = () => exps.signal("onSubscription");
        subListener.fItemUpdate = (_) => exps.signal("onItemUpdate");
        subListener.fUnsubscription = () => exps.signal("onUnsubscription");
        subListener.fRealMaxFrequency = (freq) => exps.signal('onRealMaxFrequency $freq');
        if (transport == "WS-STREAMING") {
          listener.fPropertyChange = (prop) {
            switch (prop) {
            case "clientIp":
              exps.signal("clientIp=" + client.connectionDetails.getClientIp()!);
            case "serverSocketName":
              exps.signal("serverSocketName=" + client.connectionDetails.getServerSocketName()!);
            case "sessionId":
              exps.signal("sessionId " + (client.connectionDetails.getSessionId() == null ? "is null" : "is not null"));
            case "keepaliveInterval":
              exps.signal("keepaliveInterval=" + client.connectionOptions.getKeepaliveInterval().toString());
            case "realMaxBandwidth":
              exps.signal("realMaxBandwidth=" + client.connectionOptions.getRealMaxBandwidth().toString());
            }
          };
        }
        client.connect();
        if (transport == "WS-STREAMING") {
          await exps.value("sessionId is not null");
          await exps.value("keepaliveInterval=5000");
          await exps.value("serverSocketName=Lightstreamer HTTP Server");
          await exps.value("clientIp=0:0:0:0:0:0:0:1");
          await exps.value("realMaxBandwidth=40");
        }
        client.subscribe(sub);
        await exps.value("onSubscription");
        await exps.value("onRealMaxFrequency unlimited");
        await exps.value("onItemUpdate");
        client.unsubscribe(sub);
        await exps.value("onUnsubscription");
      });

      test('message', () async {
        client.connect();
        client.sendMessage("test message ()", null, 0, null, true);
        // no outcome expected
        client.sendMessage("test message (sequence)", "test_seq", 0, null, true);
        // no outcome expected
        msgListener = new BaseMessageListener();
        msgListener.fProcessed = (msg,_) => exps.signal("onProcessed " + msg);
        client.sendMessage("test message (listener)", null, -1, msgListener, true);
        await exps.value("onProcessed test message (listener)");
        msgListener = new BaseMessageListener();
        msgListener.fProcessed = (msg,_) => exps.signal("onProcessed " + msg);
        client.sendMessage("test message (sequence+listener)", "test_seq", -1, msgListener, true);
        await exps.value("onProcessed test message (sequence+listener)");
      });

      test('message with return value', () async {
        client.connect();
        msgListener = new BaseMessageListener();
        msgListener.fProcessed = (msg,resp) => exps.signal('onProcessed `$msg` `$resp`');
        client.sendMessage("give me a result", "test_seq", -1, msgListener, true);
        await exps.value("onProcessed `give me a result` `result:ok`");
      });

      test('message with special chars', () async {
        msgListener.fProcessed = (msg,_) {
          exps.signal(msg);
        };
        client.connect();
        client.sendMessage("hello +&=%\r\n", null, -1, msgListener, false);
        await exps.value("hello +&=%\r\n");
      });

      test('unordered messages', () async {
        msgListener.fProcessed = (msg,_) {
          exps.signal(msg);
        };
        client.connect();
        client.sendMessage("test message", "UNORDERED_MESSAGES", -1, msgListener, false);
        await exps.value("test message");
      });

      test('message error', () async {
        msgListener.fDeny = (msg, code, error) {
          exps.signal('$msg $code $error');
        };
        client.connect();
        client.sendMessage("throw me an error", "test_seq", -1, msgListener, false);
        await exps.value("throw me an error -123 test error");
      });

      test('long message', () async {
        var msg = "{\"n\":\"MESSAGE_SEND\",\"c\":{\"u\":\"GEiIxthxD-1gf5Tk5O1NTw\",\"s\":\"S29120e92e162c244T2004863\",\"p\":\"localhost:3000/html/widget-responsive.html\",\"t\":\"2017-08-08T10:20:05.665Z\"},\"d\":\"{\\\"p\\\":\\\"🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐🌐\\\"}\"}";
        msgListener.fProcessed = (_,__) => exps.signal();
        client.connect();
        client.sendMessage(msg, "test_seq", -1, msgListener, false);
        await exps.value();
      });

      test('end of snapshot', () async {
        var sub = new Subscription("DISTINCT", ["end_of_snapshot"], ["value"]);
        sub.setRequestedSnapshot("yes");
        sub.setDataAdapter("END_OF_SNAPSHOT");
        subListener.fEndOfSnapshot = (name, pos) {
          exps.signal('$name $pos');
        };
        sub.addListener(subListener);
        client.subscribe(sub);
        client.connect();
        await exps.value("end_of_snapshot 1");
      });

      /**
       * Subscribes to an item and verifies the overflow event is notified to the client.
       * <br>To ease the overflow event, the test
       * <ul>
       * <li>limits the event buffer size (see max_buffer_size in Test_integration/conf/test_conf.xml)</li>
       * <li>limits the bandwidth (see {@link ConnectionOptions#setRequestedMaxBandwidth(String)})</li>
       * <li>requests "unfiltered" messages (see {@link Subscription#setRequestedMaxFrequency(String)}).</li>
       * </ul>
       */
      test('overflow', () async {
        var sub = new Subscription("MERGE", ["overflow"], ["value"]);
        sub.setRequestedSnapshot("yes");
        sub.setDataAdapter("OVERFLOW");
        sub.setRequestedMaxFrequency("unfiltered");
        subListener.fItemLostUpdates = (name, pos, lost) {
          exps.signal('$name $pos');
          client.unsubscribe(sub);
        };
        subListener.fUnsubscription = () {
          exps.signal("onUnsubscription");
        };
        sub.addListener(subListener);
        client.subscribe(sub);
        // NB the bandwidth must not be too low otherwise the server can't write the response
        client.connectionOptions.setRequestedMaxBandwidth("10");
        client.connect();
        await exps.value("overflow 1");
        await exps.value("onUnsubscription");
      });

      test('frequency', () async {
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fRealMaxFrequency = (freq) {
          exps.signal(freq!);
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("unlimited");
      });

      test('change frequency', () async {
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setDataAdapter("COUNT");
        sub.addListener(subListener);
        subListener.fRealMaxFrequency = (freq) {
          exps.signal("frequency=" + freq!);
        };
        sub.setRequestedMaxFrequency("unlimited");
        client.subscribe(sub);
        client.connect();
        await exps.value("frequency=unlimited");
        sub.setRequestedMaxFrequency("2.5");
        await exps.value("frequency=2.5");
        sub.setRequestedMaxFrequency("unlimited");
        await exps.value("frequency=unlimited");
      });

      test('headers', () async {
        client.connectionOptions.setHttpExtraHeaders({"hello" : "header"});
        var hs = client.connectionOptions.getHttpExtraHeaders()!;
        assertEqual("header", hs["hello"]);

        var expected = "CONNECTED:" + transport;
        listener.fStatusChange = (status) {
          if (status == expected) exps.signal();
        };
        client.connect();
        if (transport.startsWith("WS")){
          // ws doesn't support extra headers
          assertEqual("DISCONNECTED", client.getStatus());
        } else {
          await exps.value();
        }
      });

      test('json patch', () async {
        var updates = <ItemUpdate>[];
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("JSON_COUNT");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        await exps.value("onItemUpdate");
        var u = updates[1];
        var patch = u.getValueAsJSONPatchIfAvailable(1)!;
        patch = js.getProperty(patch, "0");
        assertEqual("replace", js.getProperty(patch, "op"));
        assertEqual("/value", js.getProperty(patch, "path"));
        expect(js.getProperty(patch, "value"), isA<int>());
        expect(u.getValue(1), isNotNull);
      });

      test('diff patch', () async {
        var updates = <ItemUpdate>[];
        var sub = new Subscription("MERGE", ["count"], ["count"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("DIFF_COUNT");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        await exps.value("onItemUpdate");
        var u = updates[1];
        expect(u.getValue(1), matches('value=\\d+'));
      });

      test('null field', () async {
        var updates = <ItemUpdate>[];
        var sub = Subscription("MERGE", ["null_item"], ["null_field"]);
        sub.setRequestedSnapshot("no");
        sub.setDataAdapter("NULL_ITEM");
        sub.addListener(subListener);
        subListener.fItemUpdate = (update) {
          updates.add(update);
          exps.signal("onItemUpdate");
        };
        client.subscribe(sub);
        client.connect();
        await exps.value("onItemUpdate");
        var u = updates[0];
        expect(u.getValue(1), isNull);
        expect(u.getValue("null_field"), isNull);
      });

    }); // group
  }); // for each group
} // main
