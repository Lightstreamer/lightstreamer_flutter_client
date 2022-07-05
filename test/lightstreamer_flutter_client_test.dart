import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_flutter_client.dart';

void main() {
  const MethodChannel channel = MethodChannel('lightstreamer_flutter_client');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('connect', () async {
    await LightstreamerFlutterClient.connect(
        "https://push.lightstreamer.com", "WELCOME", {});

    await Future.delayed(Duration(seconds: 2));

    expect(
        await LightstreamerFlutterClient.getStatus(), 'CONNECTED:WS-STREAMING');
  });
}
