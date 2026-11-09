@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';
import 'package:test/test.dart';

@JS('interopFixture.update')
external ItemUpdate _update();

@JS('interopFixture.subscription')
external Subscription _subscription();

@JS('interopFixture.notify')
external void _notify(
    JSObject source, String method, JSArray<JSAny?> arguments);

@JS('interopFixture.captureMessages')
external _Messages _captureMessages(LightstreamerClient client);

extension type _Messages(JSObject _) implements JSObject {
  external int count();
  external JSArray<JSAny?> args(int index);
  external bool sameListener(int a, int b);
  external void notify(int index, String method, JSArray<JSAny?> arguments);
}

void _event(Object source, String method, List<Object?> arguments) =>
    _notify(source as JSObject, method, arguments.jsify()! as JSArray<JSAny?>);

void main() {
  test('literal names and MPN copies preserve explicit lists', () {
    final names = [
      'item one',
      '42',
      '&=|%',
      'caff\u00e8',
      'line\nbreak',
      'a\u0000b'
    ];
    final sub = Subscription('COMMAND', names, ['key', 'command', ...names]);
    sub.setCommandSecondLevelFields(names);
    expect(sub.getItems(), names);
    expect(sub.getFields(), ['key', 'command', ...names]);
    expect(sub.getCommandSecondLevelFields(), names);
    final source = Subscription('MERGE', names, names);
    final mpn = MpnSubscription.fromSubscription(source);
    final copy = MpnSubscription.fromMpnSubscription(mpn);
    expect(mpn.getItems(), names);
    expect(copy.getFields(), names);
    expect(() => Subscription('MERGE', names), throwsA(anything));
    expect(() => mpn.setItems(['']), throwsA(anything));
    expect(() => copy.setFields([]), throwsA(anything));
    sub.setCommandSecondLevelFields(null);
    expect(sub.getCommandSecondLevelFields(), isNull);
  });

  test('Dart string collections cross constructors and setters', () {
    final sub = Subscription('COMMAND');
    expect(SubscriptionExt(sub).getItems(), isNull);
    expect(sub.getFields(), isNull);
    sub.setItems(['one', 'two']);
    sub.setFields(['key', 'command']);
    sub.setCommandSecondLevelFields(['extra']);
    expect(sub.getItems(), isA<List<String>>());
    expect(sub.getItems(), ['one', 'two']);
    expect(sub.getFields(), ['key', 'command']);
    expect(sub.getCommandSecondLevelFields(), ['extra']);
    sub.setItems(null);
    sub.setFields(null);
    sub.setCommandSecondLevelFields(null);
    expect(sub.getItems(), isNull);
    expect(sub.getFields(), isNull);
    expect(sub.getCommandSecondLevelFields(), isNull);

    final mpn = MpnSubscription('MERGE', ['one'], ['field']);
    expect(MpnSubscriptionExt(mpn).getItems(), ['one']);
    expect(mpn.getFields(), isA<List<String>>());
    mpn.setItems(['two']);
    mpn.setFields(['other']);
    expect(mpn.getItems(), ['two']);
    expect(mpn.getFields(), ['other']);
    mpn.setItems(null);
    mpn.setFields(null);
    expect(mpn.getItems(), isNull);
    expect(mpn.getFields(), isNull);

    // Empty subscription lists are invalid; validation still comes from the SDK.
    expect(() => Subscription('MERGE', [], ['field']), throwsA(anything));
    expect(() => mpn.setFields([]), throwsA(anything));
  });

  test('map and builder conversions preserve null, empty and string values',
      () {
    final client = LightstreamerClient('http://localhost:8080', 'TEST');
    final options = client.connectionOptions;
    final firebase = FirebaseMpnBuilder();
    final safari = SafariMpnBuilder();
    for (final value in <Map<String, String>?>[
      null,
      {},
      {'unicode': 'caff\u00e8', 'empty': '', 'number': '42'}
    ]) {
      options.setHttpExtraHeaders(value);
      expect(options.getHttpExtraHeaders(), value);
      expect(firebase.setData(value), same(firebase));
      expect(firebase.setHeaders(value), same(firebase));
      expect(firebase.getData(), value);
      expect(firebase.getHeaders(), value);
      if (value != null) {
        expect(options.getHttpExtraHeaders(), isA<Map<String, String>>());
        expect(firebase.getData(), isA<Map<String, String>>());
        expect(firebase.getHeaders(), isA<Map<String, String>>());
      }
    }
    for (final value in <List<String>?>[
      null,
      [],
      ['one', '', '42']
    ]) {
      expect(safari.setUrlArguments(value), same(safari));
      expect(SafariMpnBuilderExt(safari).getUrlArguments(), value);
      if (value != null) {
        expect(safari.getUrlArguments(), isA<List<String>>());
      }
    }
    expect(firebase.setTitle('title').setBody('body').setIcon('icon'),
        same(firebase));
    expect(FirebaseMpnBuilder(firebase.build()).getTitle(), 'title');
    expect(safari.setTitle('title').setBody('body').setAction('action'),
        same(safari));
    expect(SafariMpnBuilder(safari.build()).getTitle(), 'title');
  });

  test('SDK object lists retain identity and public logging inheritance', () {
    final client = LightstreamerClient('http://localhost:8080', 'TEST');
    final sub = Subscription('MERGE', ['one'], ['field']);
    expect(LightstreamerClientExt(client).getSubscriptions(),
        isA<List<Subscription>>());
    expect(client.getSubscriptions(), isEmpty);
    client.subscribe(sub);
    expect(client.getSubscriptions().single, same(sub));
    client.unsubscribe(sub);
    expect(client.getSubscriptions(), isEmpty);
    expect(() => client.getMpnSubscriptions(null), throwsA(anything));
    client.registerForMpn(MpnDevice('token', 'app', 'Google'));
    expect(client.getMpnSubscriptions(null), isA<List<MpnSubscription>>());
    expect(client.getMpnSubscriptions(null), isEmpty);
  });

  test('field selectors and JSON patches preserve JS value shape', () {
    final update = _update();
    expect(ItemUpdateExt(update).getItemName(), 'item');
    expect(update.getItemPos(), isA<int>());
    expect(update.isSnapshot(), isTrue);
    for (final selector in <StringOrInt>['field', 1]) {
      expect(update.getValue(selector), 'value');
      expect(update.isValueChanged(selector), isTrue);
      final Object? result = update.getValueAsJSONPatchIfAvailable(selector);
      final patch = (result! as JSArray<JSObject>).toDart.single;
      final value = patch.getProperty<JSObject>('value'.toJS);
      expect(value.getProperty<JSNumber>('integer'.toJS).dartify(), isA<int>());
      expect(value.dartify(), {
        'integer': 42,
        'decimal': 1.5,
        'nested': [
          null,
          {'enabled': true}
        ]
      });
    }
    for (final selector in <StringOrInt>['nullable', 2]) {
      expect(update.getValue(selector), isNull);
      expect(update.isValueChanged(selector), isFalse);
      expect(update.getValueAsJSONPatchIfAvailable(selector), isNull);
    }
    final sub = _subscription();
    expect(sub.getValue('item', 2), 'string:item/number:2');
    expect(sub.getValue(1, 'field'), 'number:1/string:field');
    expect(sub.getCommandValue(1, 'key', 'field'), 'number:1/key/string:field');
    expect(sub.getCommandValue('item', 'key', 2), 'string:item/key/number:2');
  });

  test('both item iterators are synchronous and preserve nullable arguments',
      () {
    final update = _update();
    final values = <List<Object?>>[];
    update.forEachField((name, position, value) {
      expect(position, isA<int>());
      values.add([name, position, value]);
    });
    expect(values, [
      ['field', 1, 'value'],
      [null, 2, null]
    ]);
    values.clear();
    update.forEachChangedField((name, position, value) {
      values.add([name, position, value]);
    });
    expect(values, [
      [null, 2, null]
    ]);
  });

  test('client listener identity, lifecycle and callback values', () async {
    final a = LightstreamerClient('http://localhost:8080', 'TEST');
    final b = LightstreamerClient('http://localhost:8080', 'TEST');
    final listener = _ClientEvents();
    a.addListener(listener);
    a.addListener(listener);
    b.addListener(listener);
    expect(a.getListeners(), [same(listener)]);
    expect(b.getListeners(), [same(listener)]);
    await listener.started.future;
    _event(a, 'onStatusChange', ['CONNECTED:WS-STREAMING']);
    _event(a, 'onServerError', [42, 'error']);
    _event(a, 'onPropertyChange', ['user']);
    _event(a, 'onServerKeepalive', []);
    _event(a, 'onDataAdapterStateChange', ['DISABLED', 'data adapter']);
    _event(a, 'onMetadataAdapterStateChange', ['ACTIVE']);
    expect(listener.events, [
      ['CONNECTED:WS-STREAMING'],
      [42, 'error'],
      ['user'],
      [],
      ['DISABLED', 'data adapter'],
      ['ACTIVE']
    ]);
    a.removeListener(listener);
    a.removeListener(listener);
    expect(a.getListeners(), isEmpty);
    expect(b.getListeners().single, same(listener));
    b.removeListener(listener);
    await listener.ended.future;
    a.addListener(listener);
    expect(a.getListeners().single, same(listener));
    a.removeListener(listener);
  });

  test('subscription listener identity and SDK callback objects', () async {
    final a = Subscription('MERGE', ['one'], ['field']);
    final b = Subscription('MERGE', ['two'], ['field']);
    final listener = _SubscriptionEvents();
    a.addListener(listener);
    a.addListener(listener);
    b.addListener(listener);
    expect(a.getListeners(), [same(listener)]);
    expect(b.getListeners(), [same(listener)]);
    await listener.started.future;
    final update = _update();
    _notify(a as JSObject, 'onItemUpdate', <JSAny?>[update as JSObject].toJS);
    _event(a, 'onClearSnapshot', ['one', 2]);
    _event(a, 'onEndOfSnapshot', ['one', 2]);
    _event(a, 'onItemStale', ['one', 2]);
    _event(a, 'onItemResume', ['one', 2]);
    _event(a, 'onItemLostUpdates', ['one', 2, 3, true]);
    _event(a, 'onItemLostUpdates', ['one', 2, 7, false]);
    _event(a, 'onItemLostUpdates', ['one', 2, -1, false]);
    _event(a, 'onCommandSecondLevelItemLostUpdates', [4, 'key']);
    _event(a, 'onCommandSecondLevelSubscriptionError', [5, 'error', 'key']);
    _event(a, 'onRealMaxFrequency', [null]);
    _event(a, 'onRealMaxFrequency', ['1.5']);
    _event(a, 'onSubscriptionError', [6, 'error']);
    _event(a, 'onSubscription', []);
    _event(a, 'onUnsubscription', []);
    expect(listener.update, same(update));
    expect(listener.update!.getValue(1), 'value');
    expect(listener.events, [
      ['one', 2],
      ['one', 2],
      ['one', 2],
      ['one', 2],
      ['one', 2, 3, true],
      ['one', 2, 7, false],
      ['one', 2, -1, false],
      [4, 'key'],
      [5, 'error', 'key'],
      [null],
      ['1.5'],
      [6, 'error'],
      [],
      []
    ]);
    a.removeListener(listener);
    a.removeListener(listener);
    expect(a.getListeners(), isEmpty);
    expect(b.getListeners().single, same(listener));
    b.removeListener(listener);
    await listener.ended.future;
  });

  test('MPN device listener identity, lifecycle, timestamps and errors',
      () async {
    final a = MpnDevice('token', 'app', 'Google');
    final b = MpnDevice('other', 'app', 'Google');
    final listener = _DeviceEvents();
    a.addListener(listener);
    a.addListener(listener);
    b.addListener(listener);
    expect(a.getListeners(), [same(listener)]);
    expect(b.getListeners(), [same(listener)]);
    await listener.started.future;
    _event(a, 'onStatusChanged', ['REGISTERED', 1234567890123]);
    _event(a, 'onRegistrationFailed', [42, 'error']);
    _event(a, 'onRegistered', []);
    _event(a, 'onResumed', []);
    _event(a, 'onSuspended', []);
    _event(a, 'onSubscriptionsUpdated', []);
    expect(listener.events, [
      ['REGISTERED', 1234567890123],
      [42, 'error'],
      [],
      [],
      [],
      []
    ]);
    a.removeListener(listener);
    a.removeListener(listener);
    expect(a.getListeners(), isEmpty);
    expect(b.getListeners().single, same(listener));
    b.removeListener(listener);
    await listener.ended.future;
  });

  test('MPN subscription listener identity, lifecycle and callbacks', () async {
    final a = MpnSubscription('MERGE', ['one'], ['field']);
    final b = MpnSubscription('MERGE', ['two'], ['field']);
    final listener = _MpnEvents();
    a.addListener(listener);
    a.addListener(listener);
    b.addListener(listener);
    expect(a.getListeners(), [same(listener)]);
    expect(b.getListeners(), [same(listener)]);
    await listener.started.future;
    _event(a, 'onStatusChanged', ['SUBSCRIBED', 1234567890123]);
    _event(a, 'onModificationError', [42, 'error', 'property']);
    _event(a, 'onPropertyChanged', ['property']);
    _event(a, 'onSubscriptionError', [43, 'error']);
    _event(a, 'onUnsubscriptionError', [44, 'error']);
    _event(a, 'onSubscription', []);
    _event(a, 'onUnsubscription', []);
    _event(a, 'onTriggered', []);
    expect(listener.events, [
      ['SUBSCRIBED', 1234567890123],
      [42, 'error', 'property'],
      ['property'],
      [43, 'error'],
      [44, 'error'],
      [],
      [],
      []
    ]);
    a.removeListener(listener);
    a.removeListener(listener);
    expect(a.getListeners(), isEmpty);
    expect(b.getListeners().single, same(listener));
    b.removeListener(listener);
    await listener.ended.future;
  });

  test('message listener adapter reuse, optional arguments and callbacks', () {
    final a = LightstreamerClient('http://localhost:8080', 'TEST');
    final b = LightstreamerClient('http://localhost:8080', 'TEST');
    final messages = _captureMessages(a);
    final otherMessages = _captureMessages(b);
    final listener = _MessageEvents();
    a.sendMessage('omitted');
    a.sendMessage('null', null, null, null, null);
    a.sendMessage('one', 'sequence', 12, listener, true);
    a.sendMessage('two', null, null, listener);
    b.sendMessage('three', null, null, listener, false);
    expect(messages.count(), 4);
    expect(messages.args(0).dartify(), ['omitted', null, null, null, null]);
    expect(messages.args(1).dartify(), ['null', null, null, null, null]);
    final args = messages.args(2).toDart;
    expect(args[0].dartify(), 'one');
    expect(args[1].dartify(), 'sequence');
    expect(args[2].dartify(), 12);
    expect(args[4].dartify(), true);
    expect(messages.sameListener(2, 3), isTrue);
    expect(args[3], same(otherMessages.args(0).toDart[3]));
    for (final event in <String, List<Object?>>{
      'onAbort': ['one', true],
      'onDeny': ['one', 42, 'error'],
      'onDiscarded': ['one'],
      'onError': ['one'],
      'onProcessed': ['one', 'response']
    }.entries) {
      messages.notify(2, event.key, event.value.jsify()! as JSArray<JSAny?>);
    }
    expect(listener.events, [
      ['one', true],
      ['one', 42, 'error'],
      ['one'],
      ['one'],
      ['one', 'response']
    ]);
  });
}

mixin _Lifecycle {
  final started = Completer<void>();
  final ended = Completer<void>();
  final events = <List<Object?>>[];

  void onListenStart(void dummy) {
    if (!started.isCompleted) started.complete();
  }

  void onListenEnd(void dummy) {
    if (!ended.isCompleted) ended.complete();
  }
}

class _ClientEvents extends ClientListener with _Lifecycle {
  @override
  void onDataAdapterStateChange(String state, String dataAdapterName) =>
      events.add([state, dataAdapterName]);
  @override
  void onMetadataAdapterStateChange(String state) => events.add([state]);
  @override
  void onStatusChange(String status) => events.add([status]);
  @override
  void onServerError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
  @override
  void onPropertyChange(String property) => events.add([property]);
  @override
  void onServerKeepalive() => events.add([]);
}

class _SubscriptionEvents extends SubscriptionListener with _Lifecycle {
  @override
  void onItemStale(String itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  @override
  void onItemResume(String itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  ItemUpdate? update;
  @override
  void onItemUpdate(ItemUpdate update) => this.update = update;
  @override
  void onClearSnapshot(String itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  @override
  void onEndOfSnapshot(String itemName, int itemPos) =>
      events.add([itemName, itemPos]);
  @override
  void onItemLostUpdates(
          String itemName, int itemPos, int lostUpdates, bool isOverflow) =>
      events.add([itemName, itemPos, lostUpdates, isOverflow]);
  @override
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) =>
      events.add([lostUpdates, key]);
  @override
  void onCommandSecondLevelSubscriptionError(
          int errorCode, String errorMessage, String key) =>
      events.add([errorCode, errorMessage, key]);
  @override
  void onRealMaxFrequency(String? frequency) => events.add([frequency]);
  @override
  void onSubscriptionError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
  @override
  void onSubscription() => events.add([]);
  @override
  void onUnsubscription() => events.add([]);
}

class _DeviceEvents extends MpnDeviceListener with _Lifecycle {
  @override
  void onStatusChanged(String status, int timestamp) =>
      events.add([status, timestamp]);
  @override
  void onRegistrationFailed(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
  @override
  void onRegistered() => events.add([]);
  @override
  void onResumed() => events.add([]);
  @override
  void onSuspended() => events.add([]);
  @override
  void onSubscriptionsUpdated() => events.add([]);
}

class _MpnEvents extends MpnSubscriptionListener with _Lifecycle {
  @override
  void onStatusChanged(String status, int timestamp) =>
      events.add([status, timestamp]);
  @override
  void onModificationError(
          int errorCode, String errorMessage, String propertyName) =>
      events.add([errorCode, errorMessage, propertyName]);
  @override
  void onPropertyChanged(String propertyName) => events.add([propertyName]);
  @override
  void onSubscriptionError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
  @override
  void onUnsubscriptionError(int errorCode, String errorMessage) =>
      events.add([errorCode, errorMessage]);
  @override
  void onSubscription() => events.add([]);
  @override
  void onUnsubscription() => events.add([]);
  @override
  void onTriggered() => events.add([]);
}

class _MessageEvents extends ClientMessageListener {
  final events = <List<Object?>>[];
  @override
  void onAbort(String originalMessage, bool sentOnNetwork) =>
      events.add([originalMessage, sentOnNetwork]);
  @override
  void onDeny(String originalMessage, int errorCode, String errorMessage) =>
      events.add([originalMessage, errorCode, errorMessage]);
  @override
  void onDiscarded(String originalMessage) => events.add([originalMessage]);
  @override
  void onError(String originalMessage) => events.add([originalMessage]);
  @override
  void onProcessed(String originalMessage, String response) =>
      events.add([originalMessage, response]);
}
