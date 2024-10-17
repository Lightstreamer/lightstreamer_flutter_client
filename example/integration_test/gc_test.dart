import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import './utils.dart';

/// Garbage collection is forced through aggressive memory allocation during a specified time period (`timeout`).
/// If, after this period, the unaccessible objects are still allocated, increasing the default time may help.
void main() {
  const timeout = Duration(milliseconds: 200);
  final bridge = NativeBridge.instance;
  LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(ConsoleLogLevel.WARN));

  tearDown(() async {
    await forceGC(timeout: timeout);
    bridge.cleanResources();
  });

  test('collect clients', () async {
    Object? client = LightstreamerClient(null, null);
    var ref = WeakReference(client);

    client = null;

    await forceGC(timeout: timeout);
    expect(ref.target, isNull);
    expect(bridge.nClients, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 0);
  });

  test('collect subscriptions', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    var clientRef = WeakReference(client);
    Subscription? sub = Subscription("MERGE", ['itm'], ['fld']);
    var subRef = WeakReference(sub);
    client.subscribe(sub);

    sub = null;

    await forceGC(timeout: timeout);
    expect(subRef.target, isNotNull);

    client = null;

    await forceGC(timeout: timeout);
    expect(clientRef.target, isNull);
    expect(subRef.target, isNull);

    expect(bridge.nClients, 1);
    expect(bridge.nSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 0);
    expect(bridge.nSubscriptions, 0);
  });

  test('collect inactive subscriptions', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    Subscription? sub = Subscription("MERGE", ['itm'], ['fld']);
    var subRef = WeakReference(sub);
    client.subscribe(sub);

    sub = null;

    await forceGC(timeout: timeout);
    expect(subRef.target, isNotNull);

    client.unsubscribe(subRef.target!);
    
    await forceGC(timeout: timeout);
    expect(subRef.target, isNull);

    expect(bridge.nClients, 1);
    expect(bridge.nSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 1);
    expect(bridge.nSubscriptions, 0);
  });

  test('collect mpn device', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    var clientRef = WeakReference(client);
    MpnDevice? device = MpnDevice();
    var deviceRef = WeakReference(device);
    client.registerForMpn(device);

    device = null;

    await forceGC(timeout: timeout);
    expect(deviceRef.target, isNotNull);

    client = null;

    await forceGC(timeout: timeout);
    expect(clientRef.target, isNull);
    expect(deviceRef.target, isNull);

    expect(bridge.nClients, 1);
    expect(bridge.nDevices, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 0);
    expect(bridge.nDevices, 0);
  });

  test('collect mpn subscriptions', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    var clientRef = WeakReference(client);
    var device = MpnDevice();
    await client.registerForMpn(device);
    MpnSubscription? sub = MpnSubscription("MERGE", ['itm'], ['fld']);
    if (Platform.isAndroid) {
      sub.setNotificationFormat(await FirebaseMpnBuilder().setTitle("title").build());
    } else {
      sub.setNotificationFormat(await ApnsMpnBuilder().setTitle("title").build());
    }
    var subRef = WeakReference(sub);
    client.subscribeMpn(sub, false);

    sub = null;

    await forceGC(timeout: timeout);
    expect(subRef.target, isNotNull);

    client = null;

    await forceGC(timeout: timeout);
    expect(clientRef.target, isNull);
    expect(subRef.target, isNull);

    expect(bridge.nClients, 1);
    expect(bridge.nMpnSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 0);
    expect(bridge.nMpnSubscriptions, 0);
  });

  test('collect inactive mpn subscriptions', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    var device = MpnDevice();
    await client.registerForMpn(device);
    MpnSubscription? sub = MpnSubscription("MERGE", ['itm'], ['fld']);
    if (Platform.isAndroid) {
      sub.setNotificationFormat(await FirebaseMpnBuilder().setTitle("title").build());
    } else {
      sub.setNotificationFormat(await ApnsMpnBuilder().setTitle("title").build());
    }
    var subRef = WeakReference(sub);
    client.subscribeMpn(sub, false);

    sub = null;

    await forceGC(timeout: timeout);
    expect(subRef.target, isNotNull);

    client.unsubscribeMpn(subRef.target!);
    
    await forceGC(timeout: timeout);
    expect(subRef.target, isNull);

    expect(bridge.nClients, 1);
    expect(bridge.nMpnSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nClients, 1);
    expect(bridge.nMpnSubscriptions, 0);
  });
}
