@JS('lightstreamer')
library lightstreamer_client_web;

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class LightstreamerClient {
  external static void setLoggerProvider(LoggerProvider logger);
  external factory LightstreamerClient(String serverAddress, String adapterSet);
}

extension LightstreamerClientExt on LightstreamerClient {
  external ConnectionDetails get connectionDetails;
  external ConnectionOptions get connectionOptions;
  external void connect();
  external void disconnect();
  external String getStatus();
  @JS('addListener') external void _addListener(_ClientListener listener);
  @JS('removeListener') external void _removeListener(_ClientListener listener);
  @JS('getListeners') external List<dynamic> _getListeners();
  @JS('sendMessage') external void _sendMessage(String msg, [String? sequence, int? delayTimeout, _ClientMessageListener? listener, bool? enqueueWhileDisconnected]);
  external void subscribe(Subscription subscription);
  external void unsubscribe(Subscription subscription);
  @JS('getSubscriptions') external List<dynamic> _getSubscriptions();

  void addListener(ClientListener listener) {
    _addListener(listener._asJSObject);
  }
  void removeListener(ClientListener listener) {
    _removeListener(listener._asJSObject);
  }
  List<ClientListener> getListeners() {
    return _getListeners().map((obj) => (obj as _ClientListener)._asDartObject).toList();
  }
  void sendMessage(String msg, [String? sequence, int? delayTimeout, ClientMessageListener? listener, bool? enqueueWhileDisconnected]) {
    _sendMessage(msg, sequence, delayTimeout, listener?._asJSObject, enqueueWhileDisconnected);
  }
  List<Subscription> getSubscriptions() {
    return _getSubscriptions().cast<Subscription>();
  }

  external void registerForMpn(MpnDevice device);
  external void subscribeMpn(MpnSubscription subscription, bool coalescing);
  external void unsubscribeMpn(MpnSubscription subscription);
  external void unsubscribeMpnSubscriptions(String? filter);
  @JS('getMpnSubscriptions') external List<dynamic> _getMpnSubscriptions(String? filter);
  external MpnSubscription? findMpnSubscription(String subscriptionId);

  List<MpnSubscription> getMpnSubscriptions(String? filter) {
    return _getMpnSubscriptions(filter).cast<MpnSubscription>();
  }
}

@JS()
@staticInterop
class _ClientListener {}

extension _ClientListenerExt on _ClientListener {
  external ClientListener get _asDartObject;
}

@JSExport()
abstract class ClientListener {
  void onStatusChange(String status) {}
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
  void onPropertyChange(String property) {}
  void onServerError(int errorCode, String errorMessage) {}
  void onServerKeepalive() {}

  late final _ClientListener _that;
  ClientListener() {
    _that = createDartExport(this) as _ClientListener;
  }
  _ClientListener get _asJSObject => _that;
  ClientListener get _asDartObject => this;
}

@JS()
@staticInterop
class _ClientMessageListener {}

extension _ClientMessageListenerExt on _ClientMessageListener {
  external ClientMessageListener get _asDartObject;
}

@JSExport()
abstract class ClientMessageListener {
  void onAbort(String originalMessage, bool sentOnNetwork) {}
  void onDeny(String originalMessage, int errorCode, String errorMessage) {}
  void onDiscarded(String originalMessage) {}
  void onError(String originalMessage) {}
  void onProcessed(String originalMessage, String response) {}

  late final _ClientMessageListener _that;
  ClientMessageListener() {
    _that = createDartExport(this) as _ClientMessageListener;
  }
  _ClientMessageListener get _asJSObject => _that;
  ClientMessageListener get _asDartObject => this;
}

@JS()
@staticInterop
class _SubscriptionListener {}

extension _SubscriptionListenerExt on _SubscriptionListener {
  external SubscriptionListener get _asDartObject;
}

@JSExport()
abstract class SubscriptionListener {
  void onClearSnapshot(String itemName, int itemPos) {}
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {}
  void onCommandSecondLevelSubscriptionError(int errorCode, String errorMessage, String key) {}
  void onEndOfSnapshot(String itemName, int itemPos) {}
  void onItemLostUpdates(String itemName, int itemPos, int lostUpdates) {}
  void onItemUpdate(ItemUpdate updateInfo) {}
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
  void onRealMaxFrequency(String? frequency) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onUnsubscription() {}

  late final _SubscriptionListener _that;
  SubscriptionListener() {
    _that = createDartExport(this) as _SubscriptionListener;
  }
  _SubscriptionListener get _asJSObject => _that;
  SubscriptionListener get _asDartObject => this;
}

typedef StringOrInt = Object;

@JS()
@staticInterop
class ItemUpdate {}

extension ItemUpdateExt on ItemUpdate {
  @JS('forEachChangedField') external void _forEachChangedField(void Function(String? fieldName, int fieldPosition, String? value) callback);
  @JS('forEachField') external void _forEachField(void Function(String? fieldName, int fieldPosition, String? value) callback);
  external String? getItemName();
  external int getItemPos();
  external String? getValue(StringOrInt fieldNameOrPosition);
  external Object? getValueAsJSONPatchIfAvailable(StringOrInt fieldNameOrPosition);
  external bool isSnapshot();
  external bool isValueChanged(StringOrInt fieldNameOrPosition);

  void forEachChangedField(void Function(String? fieldName, int fieldPosition, String? value) callback) {
    _forEachChangedField(allowInterop(callback));
  }
  void forEachField(void Function(String? fieldName, int fieldPosition, String? value) callback) {
    _forEachField(allowInterop(callback));
  }
}

@JS()
@staticInterop
class Subscription {
  external factory Subscription(String mode, [List<String>? items, List<String>? fields]);
}

extension SubscriptionExt on Subscription {
  @JS('addListener') external void _addListener(_SubscriptionListener listener);
  @JS('getListeners') external List<dynamic> _getListeners();
  @JS('removeListener') external void _removeListener(_SubscriptionListener listener);
  external int getCommandPosition();
  external int getKeyPosition();
  external String? getCommandSecondLevelDataAdapter();
  external void setCommandSecondLevelDataAdapter(String? dataAdapter);
  @JS('getCommandSecondLevelFields') external List<dynamic>? _getCommandSecondLevelFields();
  external void setCommandSecondLevelFields(List<String>? fields);
  external String? getCommandSecondLevelFieldSchema();
  external void setCommandSecondLevelFieldSchema(String? schemaName);
  external String? getDataAdapter();
  external void setDataAdapter(String? dataAdapter);
  @JS('getFields') external List<dynamic>? _getFields();
  external void setFields(List<String>? fields);
  external String? getFieldSchema();
  external void setFieldSchema(String? schemaName);
  external String? getItemGroup();
  external void setItemGroup(String? groupName);
  @JS('getItems') external List<dynamic>? _getItems();
  external void setItems(List<String>? items);
  external String getMode();
  external String? getRequestedBufferSize();
  external void setRequestedBufferSize(String? size);
  external String? getRequestedMaxFrequency();
  external void setRequestedMaxFrequency(String? freq);
  external String? getRequestedSnapshot();
  external void setRequestedSnapshot(String? isRequired);
  external String? getSelector();
  external void setSelector(String? selector);
  external bool isActive();
  external bool isSubscribed();
  external String? getValue(StringOrInt itemNameOrPosition, StringOrInt fieldNameOrPosition);
  external String? getCommandValue(StringOrInt itemNameOrPosition, String keyValue, StringOrInt fieldNameOrPosition);

  void addListener(SubscriptionListener listener) {
    _addListener(listener._asJSObject);
  }
  void removeListener(SubscriptionListener listener) {
    _removeListener(listener._asJSObject);
  }
  List<SubscriptionListener> getListeners() {
    return _getListeners().map((obj) => (obj as _SubscriptionListener)._asDartObject).toList();
  }
  List<String>? getFields() {
    return _getFields()?.cast<String>();
  }
  List<String>? getItems() {
    return _getItems()?.cast<String>();
  }
  List<String>? getCommandSecondLevelFields() {
    return _getCommandSecondLevelFields()?.cast<String>();
  }
}

@JS()
@staticInterop
class ConnectionDetails {}

extension ConnectionDetailsExt on ConnectionDetails {
  external String? getAdapterSet();
  external void setAdapterSet(String? adapterSet);
  external String? getClientIp();
  external String? getServerAddress();
  external void setServerAddress(String? serverAddress);
  external String? getServerInstanceAddress();
  external String? getServerSocketName();
  external String? getSessionId();
  external String? getUser();
  external void setUser(String? user);
  external void setPassword(String? password);
}

@JS()
@staticInterop
class ConnectionOptions {}

extension ConnectionOptionsExt on ConnectionOptions {
  external int getContentLength();
  external void setContentLength(int contentLength);
  external int getFirstRetryMaxDelay();
  external void setFirstRetryMaxDelay(int firstRetryMaxDelay);
  external String? getForcedTransport();
  external void setForcedTransport(String? forcedTransport);
  @JS('getHttpExtraHeaders') external Object? _getHttpExtraHeaders();
  @JS('setHttpExtraHeaders') external void _setHttpExtraHeaders(Object? headers);
  external int getIdleTimeout();
  external void setIdleTimeout(int idleTimeout);
  external int getKeepaliveInterval();
  external void setKeepaliveInterval(int keepaliveInterval);
  external int getPollingInterval();
  external void setPollingInterval(int pollingInterval);
  external String? getRealMaxBandwidth();
  external int getReconnectTimeout();
  external void setReconnectTimeout(int reconnectTimeout);
  external String getRequestedMaxBandwidth();
  external void setRequestedMaxBandwidth(String maxBandwidth);
  external int getRetryDelay();
  external void setRetryDelay(int retryDelay);
  external int getReverseHeartbeatInterval();
  external void setReverseHeartbeatInterval(int reverseHeartbeatInterval);
  external int getSessionRecoveryTimeout();
  external void setSessionRecoveryTimeout(int sessionRecoveryTimeout);
  external int getStalledTimeout();
  external void setStalledTimeout(int stalledTimeout);
  external bool isCookieHandlingRequired();
  external void setCookieHandlingRequired(bool cookieHandlingRequired);
  external bool isHttpExtraHeadersOnSessionCreationOnly();
  external void setHttpExtraHeadersOnSessionCreationOnly(bool httpExtraHeadersOnSessionCreationOnly);
  external bool isServerInstanceAddressIgnored();
  external void setServerInstanceAddressIgnored(bool serverInstanceAddressIgnored);
  external bool isSlowingEnabled();
  external void setSlowingEnabled(bool slowingEnabled);

  Map<String, String>? getHttpExtraHeaders() {
    return (dartify(_getHttpExtraHeaders()) as Map<dynamic, dynamic>).cast<String, String>();
  }
  void setHttpExtraHeaders(Map<String, String>? headers) {
    _setHttpExtraHeaders(jsify(headers));
  }
}

@JS()
@staticInterop
class ConsoleLoggerProvider extends LoggerProvider {
  external factory ConsoleLoggerProvider(int level);
}

@JS()
@staticInterop
class ConsoleLogLevel {
  external static int DEBUG;
  external static int ERROR;
  external static int FATAL;
  external static int INFO;
  external static int TRACE;
  external static int WARN;
}

@JS()
@staticInterop
class LoggerProvider {}

@JS()
@staticInterop
class MpnDevice {
  external factory MpnDevice(String token, String appId, String platform);
}

extension MpnDeviceExt on MpnDevice {
  @JS('addListener') external void _addListener(_MpnDeviceListener listener);
  @JS('getListeners') external List<dynamic> _getListeners();
  @JS('removeListener') external void _removeListener(_MpnDeviceListener listener);
  external String getApplicationId();
  external String? getDeviceId();
  external String getDeviceToken();
  external String getPlatform();
  external String? getPreviousDeviceToken();
  external String getStatus();
  external int getStatusTimestamp();
  external bool isRegistered();
  external bool isSuspended();

  void addListener(MpnDeviceListener listener) {
    _addListener(listener._asJSObject);
  }
  void removeListener(MpnDeviceListener listener) {
    _removeListener(listener._asJSObject);
  }
  List<MpnDeviceListener> getListeners() {
    return _getListeners().map((obj) => (obj as _MpnDeviceListener)._asDartObject).toList();
  }
}

@JS()
@staticInterop
class _MpnDeviceListener {}

extension _MpnDeviceListenerExt on _MpnDeviceListener {
  external MpnDeviceListener get _asDartObject;
}

@JSExport()
abstract class MpnDeviceListener {
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
  void onRegistered() {}
  void onRegistrationFailed(int errorCode, String errorMessage) {}
  void onResumed() {}
  void onStatusChanged(String status, int timestamp) {}
  void onSubscriptionsUpdated() {}
  void onSuspended() {}

  late final _MpnDeviceListener _that;
  MpnDeviceListener() {
    _that = createDartExport(this) as _MpnDeviceListener;
  }
  _MpnDeviceListener get _asJSObject => _that;
  MpnDeviceListener get _asDartObject => this;
}

@JS()
@staticInterop
class MpnSubscription {
  // TODO ctor overrides
  external factory MpnSubscription(String mode, [List<String>? items, List<String>? fields]);
}

extension MpnSubscriptionExt on MpnSubscription {
  @JS('addListener') external void _addListener(_MpnSubscriptionListener listener);
  @JS('getListeners') external List<dynamic> _getListeners();
  @JS('removeListener') external void _removeListener(_MpnSubscriptionListener listener);
  external String? getDataAdapter();
  external void setDataAdapter(String? dataAdapter);
  @JS('getFields') external List<dynamic>? _getFields();
  external void setFields(List<String>? fields);
  external String? getFieldSchema();
  external void setFieldSchema(String? schemaName);
  external String? getItemGroup();
  external void setItemGroup(String? groupName);
  @JS('getItems') external List<dynamic>? _getItems();
  external void setItems(List<String>? items);
  external String getMode();
  external String? getRequestedBufferSize();
  external void setRequestedBufferSize(String? size);
  external String? getRequestedMaxFrequency();
  external void setRequestedMaxFrequency(String? freq);
  external bool isActive();
  external bool isSubscribed();
  external bool isTriggered();

  external String? getActualNotificationFormat();
  external String? getActualTriggerExpression();
  external void setTriggerExpression(String? trigger);
  external String? getNotificationFormat();
  external void setNotificationFormat(String format);
  external String getStatus();
  external int getStatusTimestamp();
  external String? getSubscriptionId();
  external String? getTriggerExpression();

  void addListener(MpnSubscriptionListener listener) {
    _addListener(listener._asJSObject);
  }
  void removeListener(MpnSubscriptionListener listener) {
    _removeListener(listener._asJSObject);
  }
  List<MpnSubscriptionListener> getListeners() {
    return _getListeners().map((obj) => (obj as _MpnSubscriptionListener)._asDartObject).toList();
  }
  List<String>? getFields() {
    return _getFields()?.cast<String>();
  }
  List<String>? getItems() {
    return _getItems()?.cast<String>();
  }
}

@JS()
@staticInterop
class _MpnSubscriptionListener {}

extension _MpnSubscriptionListenerExt on _MpnSubscriptionListener {
  external MpnSubscriptionListener get _asDartObject;
}

@JSExport()
abstract class MpnSubscriptionListener {
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
  void onModificationError(int errorCode, String errorMessage, String propertyName) {}
  void onPropertyChanged(String propertyName) {}
  void onStatusChanged(String status, int timestamp) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onTriggered() {}
  void onUnsubscription() {}
  void onUnsubscriptionError(int errorCode, String errorMessage) {}

  late final _MpnSubscriptionListener _that;
  MpnSubscriptionListener() {
    _that = createDartExport(this) as _MpnSubscriptionListener;
  }
  _MpnSubscriptionListener get _asJSObject => _that;
  MpnSubscriptionListener get _asDartObject => this;
}

@JS()
@staticInterop
class FirebaseMpnBuilder {
  external factory FirebaseMpnBuilder([String? notificationFormat]);
}

extension FirebaseMpnBuilderExt on FirebaseMpnBuilder {
  external String build();
  external String? getBody();
  @JS('getData') external Object? _getData();
  @JS('getHeaders') external Object? _getHeaders();
  external String? getIcon();
  external String? getTitle();
  external FirebaseMpnBuilder setBody(String? body);
  @JS('setData') external FirebaseMpnBuilder _setData(Object? data);
  @JS('setHeaders') external FirebaseMpnBuilder _setHeaders(Object? headers);
  external FirebaseMpnBuilder setIcon(String? icon);
  external FirebaseMpnBuilder setTitle(String? title);

  Map<String, String>? getData() {
    return (dartify(_getData()) as Map<dynamic, dynamic>).cast<String, String>();
  }
  FirebaseMpnBuilder setData(Map<String, String>? data) {
    return _setData(jsify(data));
  }
  Map<String, String>? getHeaders() {
    return (dartify(_getHeaders()) as Map<dynamic, dynamic>).cast<String, String>();
  }
  FirebaseMpnBuilder setHeaders(Map<String, String>? headers) {
    return _setHeaders(jsify(headers));
  }
}

@JS()
@staticInterop
class SafariMpnBuilder {
  external factory SafariMpnBuilder([String? notificationFormat]);
}

extension SafariMpnBuilderExt on SafariMpnBuilder {
  external String build();
  external String? getAction();
  external String? getBody();
  external String? getTitle();
  @JS('getUrlArguments') external List<dynamic>? _getUrlArguments();
  external SafariMpnBuilder setAction(String? action);
  external SafariMpnBuilder setBody(String? body);
  external SafariMpnBuilder setTitle(String? title);
  external SafariMpnBuilder setUrlArguments(List<String>? urlArguments);

  List<String>? getUrlArguments() {
    return _getUrlArguments()?.cast<String>();
  }
}
