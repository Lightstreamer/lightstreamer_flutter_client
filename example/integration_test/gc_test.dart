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

  Future<String> getFormat() async {
    return  Platform.isAndroid ? FirebaseMpnBuilder().setTitle("title").build() : ApnsMpnBuilder().setTitle("title").build();
  }

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
    var client = LightstreamerClient(null, null);
    Subscription? sub = Subscription("MERGE", ['itm'], ['fld']);
    var ref = WeakReference(sub);
    client.subscribe(sub);

    sub = null;

    await forceGC(timeout: timeout);
    expect(ref.target, isNull);
    expect(bridge.nSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nSubscriptions, 0);
  });

  test('collect mpn device', () async {
    var client = LightstreamerClient(null, null);
    MpnDevice? device = MpnDevice();
    var ref = WeakReference(device);
    await client.registerForMpn(device);

    device = null;

    await forceGC(timeout: timeout);
    expect(ref.target, isNull);
    expect(bridge.nDevices, 1);

    bridge.cleanResources();
    expect(bridge.nDevices, 0);
  }, skip: Platform.isWindows);

  test('collect mpn subscriptions', () async {
    var client = LightstreamerClient(null, null);
    var device = MpnDevice();
    await client.registerForMpn(device);
    MpnSubscription? sub = MpnSubscription("MERGE", ['itm'], ['fld']);
    sub.setNotificationFormat(await getFormat());
    var ref = WeakReference(sub);
    client.subscribeMpn(sub, false);

    sub = null;

    await forceGC(timeout: timeout);
    expect(ref.target, isNull);
    expect(bridge.nMpnSubscriptions, 1);

    bridge.cleanResources();
    expect(bridge.nMpnSubscriptions, 0);
  }, skip: Platform.isWindows);
  
  test('collect all', () async {
    LightstreamerClient? client = LightstreamerClient(null, null);
    MpnDevice? device = MpnDevice();
    await client.registerForMpn(device);
    MpnSubscription? mpnSub = MpnSubscription("MERGE", ['itm'], ['fld']);
    mpnSub.setNotificationFormat(await getFormat());
    client.subscribeMpn(mpnSub, false);
    Subscription? sub = Subscription("MERGE", ['itm'], ['fld']);
    client.subscribe(sub);

    client = null;
    device = null;
    mpnSub = null;
    sub = null;
   
    await forceGC(timeout: timeout);
    expect(bridge.nClients, 1);
    expect(bridge.nSubscriptions, 1);
    expect(bridge.nDevices, 1);
    expect(bridge.nMpnSubscriptions, 1);

    await bridge.cleanResources();
    expect(bridge.nClients, 0);
    expect(bridge.nSubscriptions, 0);
    expect(bridge.nDevices, 0);
    expect(bridge.nMpnSubscriptions, 0);
  }, skip: Platform.isWindows);
}
