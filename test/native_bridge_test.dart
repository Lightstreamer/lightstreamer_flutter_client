// 1. How these tests work
//
// Normally, the Dart part of this plugin exchanges messages with native code
// running on Android, iOS, or another supported platform. A platform channel is
// the connection used to send those messages. For example, subscribe() sends a
// request to native code, and native code later sends listener notifications back.
//
// These tests run only the Dart code: there is no native plugin or server.
// A mock is a small replacement that lets the test decide how the missing native
// code should respond. Flutter's test binary messenger lets us install these
// replacements where Dart would normally send platform messages.
//
// In setUp(), which runs before each test:
// - The _methods mock records outgoing requests in `calls` and returns null to
//   indicate completion without a result. It does not perform the requested work.
// - The _events mock returns a successful response when Flutter asks native code
//   to start sending events, but sends none itself. Instead, each test calls
//   _event() to simulate a notification arriving from the native plugin.
// A test can replace a mock handler to throw an error and check Dart's response.
//
// To test the other direction, _event() sends a fake incoming notification to
// the real Dart message handler. StandardMethodCodec converts the notification
// into the byte format expected by that handler. The helper then waits one
// asynchronous turn so listener callbacks have a chance to run.
//
// Minimal example
//
// This example belongs inside main() and uses this file's setup and helpers.
// _SubscriptionEvents is a test listener that saves received callbacks in events.
//
// test('receives a native notification', () async {
//   final client = LightstreamerClient(null, null);
//   final sub = Subscription('MERGE', ['one'], ['field']);
//   final listener = _SubscriptionEvents();
//   sub.addListener(listener);
//
//   // The mock records this request; no native subscription is created.
//   await client.subscribe(sub);
//
//   // Find the ID Dart sent, so our fake event targets the same subscription.
//   final subId = calls
//       .lastWhere((call) => call.method == 'LightstreamerClient.subscribe')
//       .arguments['subscription']['id'] as String;
//
//   // Pretend the native plugin reported that the first item is stale.
//   await _event('SubscriptionListener.onItemStale',
//       {'subId': subId, 'itemName': 'one', 'itemPos': 1});
//
//   // Check that Dart delivered the item name and position to our listener.
//   expect(listener.events, [
//     ['one', 1],
//   ]);
// });
//
// This verifies Dart's message handling, not the native plugin's behavior.
// Device-based integration tests are needed to check the actual native code.
//
// 2. Running the tests
//
// Run from the repository root:
//   flutter test test/native_bridge_test.dart
// No device, emulator, or running server is required.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

const _methods = MethodChannel('com.lightstreamer.flutter/methods');
const _events = MethodChannel('com.lightstreamer.flutter/listeners');
const _codec = StandardMethodCodec();

Future<void> _event(String method, Map<String, Object?> arguments) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _events.name,
    _codec.encodeSuccessEnvelope({'targetMethod': method, ...arguments}),
    (_) {},
  );
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(_events, (_) async => null);
    messenger.setMockMethodCallHandler(_methods, (call) async {
      calls.add(call);
      return null;
    });
  });

  test('explicit lists validate without restricting literal names', () {
    final names = [
      'item one',
      '42',
      '&=|%',
      'caff\u00e8',
      'line\nbreak',
      'a\u0000b'
    ];
    final sub = Subscription('MERGE', names, names);
    names[0] = 'changed';
    expect(sub.getItems()!.first, 'item one');
    final returned = sub.getFields()!..clear();
    expect(returned, isEmpty);
    expect(sub.getFields(), hasLength(6));
    sub.setItems(null);
    sub.setFields(null);
    expect(sub.getItems(), isNull);
    expect(sub.getFields(), isNull);
    for (final invalid in <List<String>>[
      [],
      ['']
    ]) {
      expect(() => sub.setItems(invalid), throwsArgumentError);
      expect(() => sub.setFields(invalid), throwsArgumentError);
      expect(() => MpnSubscription('MERGE', invalid, ['field']),
          throwsArgumentError);
    }
    expect(() => Subscription('MERGE', ['one']), throwsArgumentError);
    expect(
        () => MpnSubscription('MERGE', null, ['field']), throwsArgumentError);
    expect(() => Subscription('invalid'), throwsArgumentError);
    expect(() => MpnSubscription('COMMAND'), throwsArgumentError);
    expect(
        () => Subscription('COMMAND', ['one'], ['key']), throwsArgumentError);
  });

  test('missing lists fail before submission and remain correctable', () async {
    final client = LightstreamerClient(null, null);
    final sub = Subscription('MERGE');
    await expectLater(client.subscribe(sub), throwsArgumentError);
    await expectLater(client.subscribeMpn(MpnSubscription('MERGE'), false),
        throwsArgumentError);
    expect(sub.isActive(), isFalse);
    expect(calls, isEmpty);
    sub.setItems(['one']);
    sub.setFields(['field']);
    await client.subscribe(sub);
    expect(sub.isActive(), isTrue);
    expect(() => sub.setItems(null), throwsStateError);
    expect(() => sub.setFields(null), throwsStateError);
    await expectLater(client.subscribe(sub), throwsStateError);
  });

  test('failed native submission restores inactive state', () async {
    final client = LightstreamerClient(null, null);
    final sub = Subscription('MERGE', ['one'], ['field']);
    messenger.setMockMethodCallHandler(_methods, (call) async {
      if (call.method == 'LightstreamerClient.subscribe' ||
          call.method == 'LightstreamerClient.subscribeMpn') {
        throw PlatformException(code: 'test', message: 'Rejected');
      }
      return null;
    });
    await expectLater(client.subscribe(sub), throwsA(isA<PlatformException>()));
    expect(sub.isActive(), isFalse);
    sub.setItems(['corrected']);
    final mpn = MpnSubscription('MERGE', ['one'], ['field']);
    await expectLater(
        client.subscribeMpn(mpn, false), throwsA(isA<PlatformException>()));
    expect(mpn.isActive(), isFalse);
    expect(mpn.getStatus(), 'UNKNOWN');
    mpn.setItems(['corrected']);
    messenger.setMockMethodCallHandler(_methods, (_) async => null);
    await client.subscribe(sub);
    expect(sub.isActive(), isTrue);
  });

  test('cleared second-level lists are serialized on resubmission', () async {
    final client = LightstreamerClient(null, null);
    final sub = Subscription('COMMAND', ['one'], ['key', 'command']);
    sub.setCommandSecondLevelFields(['extra field']);
    await client.subscribe(sub);
    expect(() => sub.setCommandSecondLevelFields(null), throwsStateError);
    await client.unsubscribe(sub);
    sub.setCommandSecondLevelFields(null);
    await client.subscribe(sub);
    final payload = calls
        .lastWhere((call) => call.method == 'LightstreamerClient.subscribe')
        .arguments['subscription'] as Map;
    expect(payload['fields2'], isNull);
    expect(payload.keys, isNot(contains('group')));
    expect(payload.keys, isNot(contains('schema')));
    expect(payload.keys, isNot(contains('schema2')));
    expect(() => Subscription('MERGE').setCommandSecondLevelFields(['x']),
        throwsStateError);
  });

  test('native events preserve health, availability and signed loss payloads',
      () async {
    final client = LightstreamerClient(null, null);
    final listener = _ClientEvents();
    client.addListener(listener);
    final sub = Subscription('MERGE', ['one'], ['field']);
    final subListener = _SubscriptionEvents();
    sub.addListener(subListener);
    await client.subscribe(sub);
    final payload = calls
        .lastWhere((call) => call.method == 'LightstreamerClient.subscribe')
        .arguments as Map;
    final id = payload['id'] as String;
    final subId = payload['subscription']['id'] as String;
    await _event('ClientListener.onDataAdapterStateChange',
        {'id': id, 'state': 'DISABLED', 'dataAdapterName': 'data adapter'});
    await _event('ClientListener.onMetadataAdapterStateChange',
        {'id': id, 'state': 'ACTIVE'});
    await _event('ClientListener.onServerError',
        {'id': id, 'errorCode': 12, 'errorMessage': 'Incompatible Adapter'});
    await _event('SubscriptionListener.onItemStale',
        {'subId': subId, 'itemName': null, 'itemPos': 1});
    await _event('SubscriptionListener.onItemResume',
        {'subId': subId, 'itemName': 'one', 'itemPos': 1});
    for (final loss in [(3, true), (7, false), (-1, false)]) {
      await _event('SubscriptionListener.onItemLostUpdates', {
        'subId': subId,
        'itemName': 'one',
        'itemPos': 1,
        'lostUpdates': loss.$1,
        'isOverflow': loss.$2,
      });
    }
    await _event('SubscriptionListener.onCommandSecondLevelItemLostUpdates',
        {'subId': subId, 'lostUpdates': 4, 'key': 'second level'});
    for (final code in [6, 63, 64]) {
      await _event('SubscriptionListener.onSubscriptionError', {
        'subId': subId,
        'errorCode': code,
        'errorMessage': 'Adapter failure'
      });
    }
    expect(listener.events, [
      ['DISABLED', 'data adapter'],
      ['ACTIVE'],
      [12, 'Incompatible Adapter'],
    ]);
    expect(subListener.events, [
      [null, 1],
      ['one', 1],
      ['one', 1, 3, true],
      ['one', 1, 7, false],
      ['one', 1, -1, false],
      [4, 'second level'],
      [6, 'Adapter failure'],
      [63, 'Adapter failure'],
      [64, 'Adapter failure'],
    ]);
    sub.removeListener(subListener);
    await _event('SubscriptionListener.onItemStale',
        {'subId': subId, 'itemName': 'one', 'itemPos': 1});
    expect(subListener.events, hasLength(9));
  });

  test('server-created MPN subscriptions decode typed explicit lists',
      () async {
    messenger.setMockMethodCallHandler(_methods, (call) async {
      if (call.method == 'LightstreamerClient.getMpnSubscriptions') {
        return {
          'result': <String>[],
          'extra': [
            {
              'id': 'server-created',
              'mode': 'MERGE',
              'items': <Object?>['item one', '42'],
              'fields': <Object?>['field one'],
              'statusTs': 1,
              'status': 'SUBSCRIBED',
            }
          ],
        };
      }
      return null;
    });
    final subscriptions =
        await LightstreamerClient(null, null).getMpnSubscriptions();
    final sub = subscriptions.single;
    expect(sub.getItems(), ['item one', '42']);
    expect(sub.getFields(), ['field one']);
    expect(() => sub.setItems(null), throwsStateError);
    expect(MpnSubscription.fromMpnSubscription(sub).getItems(),
        ['item one', '42']);
  });

  test('MPN property events refresh explicit lists before notifying', () async {
    final client = LightstreamerClient(null, null);
    final sub = MpnSubscription.fromSubscription(
        Subscription('MERGE', ['one'], ['field']));
    final copy = MpnSubscription.fromMpnSubscription(sub);
    expect(copy.getItems(), ['one']);
    expect(copy.getFields(), ['field']);
    final listener = _MpnEvents(sub);
    sub.addListener(listener);
    await client.subscribeMpn(sub, false);
    final payload = calls
        .lastWhere((call) => call.method == 'LightstreamerClient.subscribeMpn')
        .arguments['subscription'] as Map;
    await _event('MpnSubscriptionListener.onStatusChanged', {
      'mpnSubId': payload['id'],
      'status': 'ACTIVE',
      'timestamp': 1,
      'subscriptionId': null,
    });
    expect(sub.isActive(), isTrue);
    expect(() => sub.setItems(null), throwsStateError);
    expect(() => sub.setFields(null), throwsStateError);
    expect(payload.keys, isNot(contains('group')));
    expect(payload.keys, isNot(contains('schema')));
    for (final property in ['group', 'schema']) {
      await _event('MpnSubscriptionListener.onPropertyChanged', {
        'mpnSubId': payload['id'],
        'property': property,
        'value': <Object?>['new name', '42'],
      });
    }
    expect(listener.events, [
      [
        'group',
        ['new name', '42']
      ],
      [
        'schema',
        ['new name', '42']
      ],
    ]);
    await client.unsubscribeMpn(sub);
    await _event('MpnSubscriptionListener.onStatusChanged', {
      'mpnSubId': payload['id'],
      'status': 'UNKNOWN',
      'timestamp': 2,
      'subscriptionId': null,
    });
    expect(sub.isActive(), isFalse);
    sub.setItems(null);
    sub.setFields(null);
    expect(sub.getItems(), isNull);
    expect(sub.getFields(), isNull);
  });
}

class _ClientEvents extends ClientListener {
  final events = <List<Object?>>[];
  @override
  void onDataAdapterStateChange(String state, String dataAdapterName) =>
      events.add([state, dataAdapterName]);
  @override
  void onMetadataAdapterStateChange(String state) => events.add([state]);
  @override
  void onServerError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
}

class _SubscriptionEvents extends SubscriptionListener {
  final events = <List<Object?>>[];
  @override
  void onItemStale(String? itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  @override
  void onItemResume(String? itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  @override
  void onItemLostUpdates(
          String itemName, int itemPos, int lostUpdates, bool isOverflow) =>
      events.add([itemName, itemPos, lostUpdates, isOverflow]);
  @override
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) =>
      events.add([lostUpdates, key]);
  @override
  void onSubscriptionError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
}

class _MpnEvents extends MpnSubscriptionListener {
  _MpnEvents(this.sub);
  final MpnSubscription sub;
  final events = <List<Object?>>[];
  @override
  void onPropertyChanged(String propertyName) => events.add([
        propertyName,
        propertyName == 'group' ? sub.getItems() : sub.getFields(),
      ]);
}
