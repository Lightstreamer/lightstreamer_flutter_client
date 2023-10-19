import 'dart:async';
import 'package:test/test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

class BaseClientListener extends ClientListener {
  void Function(String)? _onStatusChange;
  void onStatusChange(String status) => _onStatusChange?.call(status);
  void Function(int, String)? _onServerError;
  void onServerError(int code, String msg) => _onServerError?.call(code, msg);
  void Function(String)? _onPropertyChange;
  void onPropertyChange(String property) => _onPropertyChange?.call(property);
}
class BaseSubscriptionListener extends SubscriptionListener {
  void Function()? _onSubscription;
  void onSubscription() => _onSubscription?.call();
  void Function(int, String)? _onSubscriptionError;
  void onSubscriptionError(int code, String msg) => _onSubscriptionError?.call(code, msg);
  void Function(ItemUpdate)? _onItemUpdate;
  void onItemUpdate(ItemUpdate update) => _onItemUpdate?.call(update);
  void Function()? _onUnsubscription;
  void onUnsubscription() => _onUnsubscription?.call();
}

void main() {
  late Completer<String> completer;
  late LightstreamerClient client;
  late BaseClientListener listener;
  late BaseSubscriptionListener subListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  setUp(() {
    completer = new Completer();
    client = new LightstreamerClient("http://localhost:8080", "TEST");
    listener = new BaseClientListener();
    subListener = new BaseSubscriptionListener();
    client.addListener(listener);
  });

  tearDown(() {
    client.disconnect();
  });

  test('listeners', () {
    var ls = client.getListeners();
    expect(1, ls.length);
    expect(listener == ls[0], isTrue);

    var sub = new Subscription("MERGE", ["count"], ["count"]);
    sub.addListener(subListener);
    var subls = sub.getListeners();
    expect(1, subls.length);
    expect(subListener == subls[0], isTrue);
  });

  test('connect', () async {
    var expected = "CONNECTED:WS-STREAMING";
    listener._onStatusChange = (status) {
      if (status == expected) {
        completer.complete(status);
      }
    };
    client.connect();
    await completer.future;
    expect(expected, client.getStatus());
  });

  test('online server', () async {
    client = new LightstreamerClient("https://push.lightstreamer.com", "DEMO");
    listener = new BaseClientListener();
    client.addListener(listener);

    var expected = "CONNECTED:WS-STREAMING";
    listener._onStatusChange = (status) {
      if (status == expected) {
        completer.complete(status);
      }
    };
    client.connect();
    await completer.future;
    expect(expected, client.getStatus());
  });

  test('error', () async {
    client = new LightstreamerClient("http://localhost:8080", "XXX");
    listener = new BaseClientListener();
    client.addListener(listener);
    listener._onServerError = (code, msg) {
      completer.complete('$code $msg');
    };
    client.connect();
    expect("2 Requested Adapter Set not available", await completer.future);
  });

  test('disconnect', () async {
    var transport = "WS-STREAMING";
    listener._onStatusChange = (status) {
      if (status == "CONNECTED:" + transport) {
        client.disconnect();
      } else if (status == "DISCONNECTED") {
        completer.complete(status);
      }
    };
    client.connect();
    await completer.future;
    expect("DISCONNECTED", client.getStatus());
  });

  test('subscribe', () async {
    var sub = new Subscription("MERGE", ["count"], ["count"]);
    sub.setDataAdapter("COUNT");
    sub.addListener(subListener);
    subListener._onSubscription = () {
      completer.complete('');
    };
    client.subscribe(sub);
    var subs = client.getSubscriptions();
    expect(1, subs.length);
    expect(sub == subs[0], isTrue);
    client.connect();
    await completer.future;
    expect(sub.isSubscribed(), isTrue);
  });

  test('subscription error', () async {
    var sub = new Subscription("RAW", ["count"], ["count"]);
    sub.setDataAdapter("COUNT");
    sub.addListener(subListener);
    subListener._onSubscriptionError = (code, msg) {
      completer.complete('$code $msg');
    };
    client.subscribe(sub);
    client.connect();
    expect("24 Invalid mode for these items", await completer.future);
  });

  test('subscribe command', () async {
    var sub = new Subscription("COMMAND", ["mult_table"], ["key", "value1", "value2", "command"]);
    sub.setDataAdapter("MULT_TABLE");
    sub.addListener(subListener);
    subListener._onSubscription = () {
      completer.complete('');
    };
    client.subscribe(sub);
    client.connect();
    await completer.future;
    expect(sub.isSubscribed(), isTrue);
    expect(1, sub.getKeyPosition());
    expect(4, sub.getCommandPosition());
  });

  test('subscribe command 2 levels', () async {
    var transport = "WS-STREAMING";
    var sub = new Subscription("COMMAND", ["two_level_command_count" + transport], ["key", "command"]);
    sub.setDataAdapter("TWO_LEVEL_COMMAND");
    sub.setCommandSecondLevelDataAdapter("COUNT");
    sub.setCommandSecondLevelFields(["count"]);
    sub.addListener(subListener);
    var regex = new RegExp('\\d+');
    subListener._onItemUpdate = (update) {
      var val = update.getValue("count") ?? "";
      var key = update.getValue("key") ?? "";
      var cmd = update.getValue("command") ?? "";
      if (regex.hasMatch(val) && key == "count" && cmd == "UPDATE") {
        completer.complete('');
      }
    };
    client.subscribe(sub);
    var subs = client.getSubscriptions();
    expect(1, subs.length);
    expect(sub == subs[0], isTrue);
    client.connect();
    await completer.future;
    expect(sub.isSubscribed(), isTrue);
    expect(1, sub.getKeyPosition());
    expect(2, sub.getCommandPosition());
  });

  test('unsubscribe', () async {
    var sub = new Subscription("MERGE", ["count"], ["count"]);
    sub.setDataAdapter("COUNT");
    sub.addListener(subListener);
    subListener._onSubscription = () {
      client.unsubscribe(sub);
    };
    subListener._onUnsubscription = () {
      completer.complete('');
    };
    client.subscribe(sub);
    client.connect();
    await completer.future;
    expect(sub.isSubscribed(), isFalse);
    expect(sub.isActive(), isFalse);
  });

  test('subscribe non-ascii', () async {
    var sub = new Subscription("MERGE", ["strange:àìùòlè"], ["value🌐-", "value&+=\r\n%"]);
    sub.setDataAdapter("STRANGE_NAMES");
    sub.addListener(subListener);
    subListener._onSubscription = () {
      completer.complete('');
    };
    client.subscribe(sub);
    client.connect();
    await completer.future;
  });
}