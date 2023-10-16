import 'dart:async';
import 'package:test/test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

class BaseClientListener extends ClientListener {
  void Function(String)? _onStatusChange;
  void Function(int, String)? _onServerError;
  void onStatusChange(String status) {
    _onStatusChange?.call(status);
  }
  void onServerError(int code, String msg) {
    _onServerError?.call(code, msg);
  }
}
class BaseSubscriptionListener extends SubscriptionListener {

}

void main() {
  late Completer<String> completer;
  late LightstreamerClient client;
  late BaseClientListener listener;
  late BaseSubscriptionListener subListener;
  LightstreamerClient.setLoggerProvider(new ConsoleLoggerProvider(ConsoleLogLevel.DEBUG));

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
}