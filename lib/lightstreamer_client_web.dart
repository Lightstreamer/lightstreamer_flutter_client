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
  external List<Subscription> getSubscriptions();

  void addListener(ClientListener listener) {
    _addListener(listener.asJSObject);
  }
  void removeListener(ClientListener listener) {
    _removeListener(listener.asJSObject);
  }
  List<ClientListener> getListeners() {
    return _getListeners().map((obj) => (obj as _ClientListener).asDartObject).toList();
  }
  void sendMessage(String msg, [String? sequence, int? delayTimeout, ClientMessageListener? listener, bool? enqueueWhileDisconnected]) {
    _sendMessage(msg, sequence, delayTimeout, listener?.asJSObject, enqueueWhileDisconnected);
  }
}

@JS()
@staticInterop
class _ClientListener {}

extension _ClientListenerExt on _ClientListener {
  external ClientListener get asDartObject;
}

@JSExport()
abstract class ClientListener {
  void onStatusChange(String status) {}
  void onListenEnd(Object dummy) {}
  void onListenStart(Object dummy) {}
  void onPropertyChange(String property) {}
  void onServerError(int errorCode, String errorMessage) {}
  void onServerKeepalive() {}

  late final _ClientListener _that;
  ClientListener() {
    _that = createDartExport(this) as _ClientListener;
  }
  _ClientListener get asJSObject => _that;
  ClientListener get asDartObject => this;
}

@JS()
@staticInterop
class _ClientMessageListener {}

extension _ClientMessageListenerExt on _ClientMessageListener {
  external ClientMessageListener get asDartObject;
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
  _ClientMessageListener get asJSObject => _that;
  ClientMessageListener get asDartObject => this;
}

@JS()
@staticInterop
class _SubscriptionListener {}

extension _SubscriptionListenerExt on _SubscriptionListener {
  external SubscriptionListener get asDartObject;
}

@JSExport()
abstract class SubscriptionListener {
  void onClearSnapshot(String itemName, int itemPos) {}
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {}
  void onCommandSecondLevelSubscriptionError(int errorCode, String errorMessage, String key) {}
  void onEndOfSnapshot(String itemName, int itemPos) {}
  void onItemLostUpdates(String itemName, int itemPos, int lostUpdates) {}
  void onItemUpdate(ItemUpdate updateInfo) {}
  void onListenEnd(Object dummy) {}
  void onListenStart(Object dummy) {}
  void onRealMaxFrequency(String? frequency) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onUnsubscription() {}

  late final _SubscriptionListener _that;
  SubscriptionListener() {
    _that = createDartExport(this) as _SubscriptionListener;
  }
  _SubscriptionListener get asJSObject => _that;
  SubscriptionListener get asDartObject => this;
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
    _addListener(listener.asJSObject);
  }
  void removeListener(SubscriptionListener listener) {
    _removeListener(listener.asJSObject);
  }
  List<SubscriptionListener> getListeners() {
    return _getListeners().map((obj) => (obj as _SubscriptionListener).asDartObject).toList();
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
