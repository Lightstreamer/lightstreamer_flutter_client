import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/src/client_listeners.dart';
import 'package:lightstreamer_flutter_client/src/log_manager.dart';
import 'package:lightstreamer_flutter_client/src/logger.dart';

part 'native_bridge.dart';
part 'item_update.dart';

class ConnectionDetails {
  final String _id;
  String? _adapterSet;
  String? _serverAddress;
  String? _user;
  String? _password;

  Map<String, dynamic> _toMap() {
    return {
      "adapterSet": _adapterSet,
      "serverAddress": _serverAddress,
      "user": _user,
      "password": _password
    };
  }

  ConnectionDetails._(String clientId) : _id = clientId;

  String? getAdapterSet() {
    return _adapterSet;
  }

  void setAdapterSet(String? newVal) {
    _adapterSet = newVal;
  }

  String? getServerAddress() {
    return _serverAddress;
  }

  void setServerAddress(String? newVal) {
    _serverAddress = newVal;
  }

  String? getUser() {
    return _user;
  }

  void setUser(String? newVal) {
    _user = newVal;
  }

  Future<String?> getServerInstanceAddress() async {
    return await _invokeMethod('getServerInstanceAddress');
  }

  Future<String?> getServerSocketName() async {
    return await _invokeMethod('getServerSocketName');
  }

  Future<String?> getClientIp() async {
    return await _invokeMethod('getClientIp');
  }

  Future<String?> getSessionId() async {
    return await _invokeMethod('getSessionId');
  }

  void setPassword(String? newVal) {
    _password = newVal;
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = _id;
    return await NativeBridge.instance.invokeMethod('ConnectionDetails.$method', arguments);
  }
}

class ConnectionOptions {
  // TODO keep in sync
  final String _id;
  int _contentLength = 50000000;
  int _firstRetryMaxDelay = 100;
  String? _forcedTransport;
  Map<String, String>? _httpExtraHeaders;
  int _idleTimeout = 19000;
  int _keepaliveInterval = 0;
  int _pollingInterval = 0;
  int _reconnectTimeout = 3000;
  String _requestedMaxBandwidth = "unlimited";
  int _retryDelay = 4000;
  int _reverseHeartbeatInterval = 0;
  int _sessionRecoveryTimeout = 15000;
  int _stalledTimeout = 2000;
  bool _httpExtraHeadersOnSessionCreationOnly = false;
  bool _serverInstanceAddressIgnored = false;
  bool _slowingEnabled = false;

  Map<String, dynamic> _toMap() {
    return {
      "contentLength": _contentLength,
      "firstRetryMaxDelay": _firstRetryMaxDelay,
      "forcedTransport": _forcedTransport,
      "httpExtraHeaders": _httpExtraHeaders,
      "idleTimeout": _idleTimeout,
      "keepaliveInterval": _keepaliveInterval,
      "pollingInterval": _pollingInterval,
      "reconnectTimeout": _reconnectTimeout,
      "requestedMaxBandwidth": _requestedMaxBandwidth,
      "retryDelay": _retryDelay,
      "reverseHeartbeatInterval": _reverseHeartbeatInterval,
      "sessionRecoveryTimeout": _sessionRecoveryTimeout,
      "stalledTimeout": _stalledTimeout,
      "httpExtraHeadersOnSessionCreationOnly": _httpExtraHeadersOnSessionCreationOnly,
      "serverInstanceAddressIgnored": _serverInstanceAddressIgnored,
      "slowingEnabled": _slowingEnabled
    };
  }

  ConnectionOptions._(String clientId) : _id = clientId;

  int getContentLength() {
    return _contentLength;
  }

  void setContentLength(int newVal) {
    _contentLength = newVal;
  }

  int getFirstRetryMaxDelay() {
    return _firstRetryMaxDelay;
  }

  void setFirstRetryMaxDelay(int newVal) {
    _firstRetryMaxDelay = newVal;
  }

  String? getForcedTransport() {
    return _forcedTransport;
  }

  void setForcedTransport(String? newVal) {
    _forcedTransport = newVal;
  }

  Map<String, String>? getHttpExtraHeaders() {
    return _httpExtraHeaders;
  }

  void setHttpExtraHeaders(Map<String, String>? newVal) {
    _httpExtraHeaders = newVal;
  }

  int getIdleTimeout() {
    return _idleTimeout;
  }

  void setIdleTimeout(int newVal) {
    _idleTimeout = newVal;
  }

  int getKeepaliveInterval() {
    return _keepaliveInterval;
  }

  void setKeepaliveInterval(int newVal) {
    _keepaliveInterval = newVal;
  }

  int getPollingInterval() {
    return _pollingInterval;
  }

  void setPollingInterval(int newVal) {
    _pollingInterval = newVal;
  }

  Future<String?> getRealMaxBandwidth() async {
    return await _invokeMethod('getRealMaxBandwidth');
  }

  int getReconnectTimeout() {
    return _reconnectTimeout;
  }

  void setReconnectTimeout(int newVal) {
    _reconnectTimeout = newVal;
  }

  String getRequestedMaxBandwidth() {
    return _requestedMaxBandwidth;
  }

  void setRequestedMaxBandwidth(String newVal) {
    _requestedMaxBandwidth = newVal;
  }

  int getRetryDelay() {
    return _retryDelay;
  }

  void setRetryDelay(int newVal) {
    _retryDelay = newVal;
  }

  int getReverseHeartbeatInterval() {
    return _reverseHeartbeatInterval;
  }

  void setReverseHeartbeatInterval(int newVal) {
    _reverseHeartbeatInterval = newVal;
  }

  int getSessionRecoveryTimeout() {
    return _sessionRecoveryTimeout;
  }

  void setSessionRecoveryTimeout(int newVal) {
    _sessionRecoveryTimeout = newVal;
  }

  int getStalledTimeout() {
    return _stalledTimeout;
  }

  void setStalledTimeout(int newVal) {
    _stalledTimeout = newVal;
  }

  bool isHttpExtraHeadersOnSessionCreationOnly() {
    return _httpExtraHeadersOnSessionCreationOnly;
  }

  void setHttpExtraHeadersOnSessionCreationOnly(bool newVal) {
    _httpExtraHeadersOnSessionCreationOnly = newVal;
  }

  bool isServerInstanceAddressIgnored() {
    return _serverInstanceAddressIgnored;
  }

  void setServerInstanceAddressIgnored(bool newVal) {
    _serverInstanceAddressIgnored = newVal;
  }

  bool isSlowingEnabled() {
    return _slowingEnabled;
  }

  void setSlowingEnabled(bool newVal) {
    _slowingEnabled = newVal;
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = _id;
    return await NativeBridge.instance.invokeMethod('ConnectionOptions.$method', arguments);
  }
}

class Subscription {
  static int _idGenerator = 0;
  final String _id;

  final List<SubscriptionListener> _listeners = [];
  final String _mode;
  List<String>? _items;
  List<String>? _fields;
  String? _group;
  String? _schema;
  String? _dataAdapter;
  String? _bufferSize;
  String? _snapshot;
  String? _requestedMaxFrequency;
  String? _selector;
  String? _dataAdapter2;
  List<String>? _fields2;
  String? _schema2;

  // _active is true when the subscribe method has been called and the unsubscribe method has not been called in the meantime;
  // _active is false when the unsubscribe method has been called and the subscribe method has not been called in the meantime
  bool _active = false;

  Map<String, dynamic> _toMap() {
    return {
      'id': _id,
      'mode': _mode,
      'items': _items,
      'fields': _fields,
      'group': _group,
      'schema': _schema,
      'dataAdapter': _dataAdapter,
      'bufferSize': _bufferSize,
      'snapshot': _snapshot,
      'requestedMaxFrequency': _requestedMaxFrequency,
      'selector': _selector,
      'dataAdapter2': _dataAdapter2,
      'fields2': _fields2,
      'schema2': _schema2,
    };
  }

  Subscription(String mode, [ List<String>? items, List<String>? fields ]) : 
    _id = 'sub${_idGenerator++}',
    _mode = mode, 
    _items = items?.toList(), 
    _fields = fields?.toList();

  void addListener(SubscriptionListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      scheduleMicrotask(() {
        listener.onListenStart();
      });
    }
  }

  void removeListener(SubscriptionListener listener) {
    var found = _listeners.remove(listener);
    if (found) {
      scheduleMicrotask(() {
        listener.onListenEnd();
      });
    }
  }

  List<SubscriptionListener> getListeners() {
    return _listeners.toList();
  }

  Future<int> getCommandPosition() async {
    if (!_active) {
      throw Exception('Subscription is not active');
    }
    return await _invokeMethod('getCommandPosition', -1);
  }
   Future<int> getKeyPosition() async {
    if (!_active) {
      throw Exception('Subscription is not active');
    }
    return await _invokeMethod('getKeyPosition', -1);
  }
  String? getCommandSecondLevelDataAdapter() {
    return _dataAdapter2;
  }
  void setCommandSecondLevelDataAdapter(String? dataAdapter) {
    _dataAdapter2 = dataAdapter;
  }
  List<String>? getCommandSecondLevelFields() {
    return _fields2?.toList();
  }
  void setCommandSecondLevelFields(List<String>? fields) {
    _fields2 = fields?.toList();
  }
  String? getCommandSecondLevelFieldSchema() {
    return _schema2;
  }
  void setCommandSecondLevelFieldSchema(String? schemaName) {
    _schema2 = schemaName;
  }
  String? getDataAdapter() {
    return _dataAdapter;
  }
  void setDataAdapter(String? dataAdapter) {
    _dataAdapter = dataAdapter;
  }
  List<String>? getFields() {
    return _fields?.toList();
  }
  void setFields(List<String>? fields) {
    _fields = fields?.toList();
  }
  String? getFieldSchema() {
    return _schema;
  }
  void setFieldSchema(String? schemaName) {
    _schema = schemaName;
  }
  String? getItemGroup() {
    return _group;
  }
  void setItemGroup(String? groupName) {
    _group = groupName;
  }
  List<String>? _getItems() {
    return _items?.toList();
  }
  void setItems(List<String>? items) {
    _items = items?.toList();
  }
  String getMode() {
    return _mode;
  }
  String? getRequestedBufferSize() {
    return _bufferSize;
  }
  void setRequestedBufferSize(String? size) {
    _bufferSize = size;
  }
  String? getRequestedMaxFrequency() {
    return _requestedMaxFrequency;
  }
  void setRequestedMaxFrequency(String? freq) {
    _requestedMaxFrequency = freq;
  }
  String? getRequestedSnapshot() {
    return _snapshot;
  }
  void setRequestedSnapshot(String? isRequired) {
    _snapshot = isRequired;
  }
  String? getSelector() {
    return _selector;
  }
  void setSelector(String? selector) {
    _selector = selector;
  }
  Future<bool> isActive() async {
    return await _invokeMethod('isActive', false);
  }
  Future<bool> isSubscribed() async {
    return await _invokeMethod('isSubscribed', false);
  }
  // TODO String? getValue(StringOrInt itemNameOrPosition, StringOrInt fieldNameOrPosition) {
  // }
  // TODO String? getCommandValue(StringOrInt itemNameOrPosition, String keyValue, StringOrInt fieldNameOrPosition) {
  // }

  Future<T> _invokeMethod<T>(String method, T defaultValue, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["subId"] = _id;
    return _active ? await NativeBridge.instance.invokeMethod('Subscription.$method', arguments) : defaultValue;
  }
}

class LightstreamerClient {
  static int _idGenerator = 0;

  late final String _id;
  late final ConnectionDetails connectionDetails;
  late final ConnectionOptions connectionOptions;
  final List<ClientListener> _listeners = [];

  LightstreamerClient._() : _id = '${_idGenerator++}' {
    connectionDetails = ConnectionDetails._(_id);
    connectionOptions = ConnectionOptions._(_id);
  }

  // TODO factory method or initialization method?
  static Future<LightstreamerClient> create(String? serverAddress, String? adapterSet) async {
    var client = LightstreamerClient._();
    client.connectionDetails.setServerAddress(serverAddress);
    client.connectionDetails.setAdapterSet(adapterSet);
    var arguments = <String, dynamic>{
      "id": client._id,
      "serverAddress": serverAddress,
      "adapterSet": adapterSet
    };
    await NativeBridge.instance.client_create(client._id, client, arguments);
    return client;
  }

  static Future<void> setLoggerProvider(LoggerProvider provider) async {
    var logger = provider.getLogger('lightstreamer');
    var level = logger.isDebugEnabled() ? ConsoleLogLevel.DEBUG
              : logger.isErrorEnabled() ? ConsoleLogLevel.ERROR
              : logger.isWarnEnabled()  ? ConsoleLogLevel.WARN
              : logger.isInfoEnabled()  ? ConsoleLogLevel.INFO
              : logger.isFatalEnabled() ? ConsoleLogLevel.FATAL
              : ConsoleLogLevel.TRACE;
    var arguments = <String, dynamic>{
      'level': level
    };
    LogManager.setLoggerProvider(provider);
    return await NativeBridge.instance.invokeMethod('LightstreamerClient.setLoggerProvider', arguments);
  }

  static Future<void> addCookies(String uri, List<Cookie> cookies) async {
    var arguments = <String, dynamic>{
      'uri': uri,
      'cookies': cookies.map((e) => e.toString()).toList()
    };
    return await NativeBridge.instance.invokeMethod('LightstreamerClient.addCookies', arguments);
  }

  static Future<List<Cookie>> getCookies(String uri) async {
    var arguments = <String, dynamic>{
      'uri': uri
    };
    List<String> cookies = (await NativeBridge.instance.invokeMethod('LightstreamerClient.getCookies', arguments)).cast<String>();
    return cookies.map((e) => Cookie.fromSetCookieValue(e)).toList();
  }

  Future<void> connect() async {
    var arguments = <String, dynamic>{
      "connectionDetails": connectionDetails._toMap(),
      "connectionOptions": connectionOptions._toMap(),
    };
    return await _invokeMethod('connect', arguments);
  }

  Future<void> disconnect() async {
    return await _invokeMethod('disconnect');
  }

  Future<String> getStatus() async {
    return await _invokeMethod('getStatus');
  }

  Future<void> subscribe(Subscription sub) async {
    var arguments = <String, dynamic>{
      'subscription': sub._toMap()
    };
    await NativeBridge.instance.client_subscribe(_id, sub._id, sub, arguments);
    sub._active = true;
  }

  Future<void> unsubscribe(Subscription sub) async {
    var arguments = <String, dynamic>{
      'subId': sub._id
    };
    await NativeBridge.instance.client_unsubscribe(_id, sub._id, arguments);
    sub._active = false;
  }

  Future<List<Subscription>> getSubscriptions() async {
    return await NativeBridge.instance.client_getSubscriptions(_id);
  }

  Future<void> sendMessage(String message, [String? sequence, int? delayTimeout, ClientMessageListener? listener, bool? enqueueWhileDisconnected]) async {
    var arguments = <String, dynamic>{
      'message': message,
      'sequence': sequence,
      'delayTimeout': delayTimeout,
      'enqueueWhileDisconnected': enqueueWhileDisconnected
    };
    return await NativeBridge.instance.client_sendMessage(_id, listener, arguments);
  }

  void addListener(ClientListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      scheduleMicrotask(() {
        listener.onListenStart();
      });
    }
  }

  void removeListener(ClientListener listener) {
    var found = _listeners.remove(listener);
    if (found) {
      scheduleMicrotask(() {
        listener.onListenEnd();
      });
    }
  }

  List<ClientListener> getListeners() {
    return _listeners.toList();
  }

  MpnDevice? _mpnDevice;

  MpnDevice? getMpnDevice() {
    return _mpnDevice;
  }

  Future<void> registerForMpn(MpnDevice device) async {
    // TODO what if already registered
    _mpnDevice = device;
    device._client = this;
    return await _invokeMethod('registerForMpn');
  }

  Future<void> subscribeMpn(MpnSubscription sub, bool coalescing) async {
    var arguments = <String, dynamic>{
      'subscription': sub._toMap(),
      'coalescing': coalescing
    };
    return await NativeBridge.instance.client_subscribeMpn(_id, sub._id, sub, arguments);
  }

  Future<void> unsubscribeMpn(MpnSubscription sub) async {
    var arguments = <String, dynamic>{
      'mpnSubId': sub._id
    };
    return await NativeBridge.instance.client_unsubscribeMpn(_id, sub._id, arguments);
  }

  Future<void> unsubscribeMpnSubscriptions([ String? filter ]) async {
    var arguments = <String, dynamic>{
      'filter': filter
    };
    return await _invokeMethod('unsubscribeMpnSubscriptions', arguments);
  }

  Future<List<MpnSubscription>> getMpnSubscriptions([ String? filter ]) async {
    var arguments = <String, dynamic>{
      'filter': filter
    };
    return await NativeBridge.instance.client_getMpnSubscriptions(_id, arguments);
  }

  Future<MpnSubscription?> findMpnSubscription(String subscriptionId) async {
    var arguments = <String, dynamic>{
      'subscriptionId': subscriptionId
    };
    return await NativeBridge.instance.client_findMpnSubscription(_id, arguments);
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = _id;
    return await NativeBridge.instance.invokeMethod('LightstreamerClient.$method', arguments);
  }
}

class MpnDevice {
  final List<MpnDeviceListener> _listeners = [];
  LightstreamerClient? _client;

  void addListener(MpnDeviceListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      scheduleMicrotask(() {
        listener.onListenStart();
      });
    }
  }

  void removeListener(MpnDeviceListener listener) {
    var found = _listeners.remove(listener);
    if (found) {
      scheduleMicrotask(() {
        listener.onListenEnd();
      });
    }
  }

  List<MpnDeviceListener> getListeners() {
    return _listeners.toList();
  }

  Future<String> getApplicationId() async {
    return await _invokeMethod('getApplicationId');
  }

  Future<String?> getDeviceId() async {
    return await _invokeMethod('getDeviceId');
  }

  Future<String> getDeviceToken() async {
    return await _invokeMethod('getDeviceToken');
  }

  Future<String> getPlatform() async {
    return await _invokeMethod('getPlatform');
  }

  Future<String?> getPreviousDeviceToken() async {
    return await _invokeMethod('getPreviousDeviceToken');
  }

  Future<String> getStatus() async {
    return await _invokeMethod('getStatus');
  }

  Future<int> getStatusTimestamp() async {
    return await _invokeMethod('getStatusTimestamp');
  }

  Future<bool> isRegistered() async {
    return await _invokeMethod('isRegistered');
  }

  Future<bool> isSuspended() async {
    return await _invokeMethod('isSuspended');
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    var client = _client;
    if (client == null) {
      throw Exception("This MPN device has not been registered by any client yet");
    }
    arguments = arguments ?? {};
    arguments["id"] = client._id;
    return await NativeBridge.instance.invokeMethod('MpnDevice.$method', arguments);
  }
}

class MpnSubscription {
  static int _idGenerator = 0;
  final String _id;

  final List<MpnSubscriptionListener> _listeners = [];
  String _mode;
  List<String>? _items;
  List<String>? _fields;
  String? _group;
  String? _schema;
  String? _dataAdapter;
  String? _bufferSize;
  String? _requestedMaxFrequency;
  String? _trigger;
  String? _notificationFormat;
  //
  String? _actualNotificationFormat;
  String? _actualTrigger;
  //
  int _statusTs = 0;
  String _status = 'UNKNOWN';
  //
  String? _subscriptionId;

  Map<String, dynamic> _toMap() {
    return {
      'id': _id,
      'mode': _mode,
      'items': _items,
      'fields': _fields,
      'group': _group,
      'schema': _schema,
      'dataAdapter': _dataAdapter,
      'bufferSize': _bufferSize,
      'requestedMaxFrequency': _requestedMaxFrequency,
      'trigger': _trigger,
      'notificationFormat': _notificationFormat
    };
  }

  MpnSubscription(String mode, [ List<String>? items, List<String>? fields ]) : 
    _id = 'mpnsub${_idGenerator++}',
    _mode = mode, 
    _items = items?.toList(), 
    _fields = fields?.toList();

  void addListener(MpnSubscriptionListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      scheduleMicrotask(() {
        listener.onListenStart();
      });
    }
  }

  void removeListener(MpnSubscriptionListener listener) {
    var found = _listeners.remove(listener);
    if (found) {
      scheduleMicrotask(() {
        listener.onListenEnd();
      });
    }
  }

  List<MpnSubscriptionListener> getListeners() {
    return _listeners.toList();
  }

  String? getDataAdapter() {
    return _dataAdapter;
  }
  void setDataAdapter(String? dataAdapter) {
    _dataAdapter = dataAdapter;
  }
  List<String>? getFields() {
    return _fields?.toList();
  }
  void setFields(List<String>? fields) {
    _fields = fields?.toList();
  }
  String? getFieldSchema() {
    return _schema;
  }
  void setFieldSchema(String? schemaName) {
    _schema = schemaName;
  }
  String? getItemGroup() {
    return _group;
  }
  void setItemGroup(String? groupName) {
    _group = groupName;
  }
  List<String>? getItems() {
    return _items?.toList();
  }
  void setItems(List<String>? items) {
    _items = items?.toList();
  }
  String getMode() {
    return _mode;
  }
  String? getRequestedBufferSize() {
    return _bufferSize;
  }
  void setRequestedBufferSize(String? size) {
    _bufferSize = size;
  }
  String? getRequestedMaxFrequency() {
    return _requestedMaxFrequency;
  }
  void setRequestedMaxFrequency(String? freq) {
    _requestedMaxFrequency = freq;
  }
  String? getTriggerExpression() {
    return _trigger;
  }
  Future<void> setTriggerExpression(String? trigger) async {
    _trigger = trigger;
    var arguments = <String, dynamic> {
      'trigger': trigger
    };
    return await _invokeMethod('setTriggerExpression', arguments);
  }
  String? getNotificationFormat() {
    return _notificationFormat;
  }
  Future<void> setNotificationFormat(String format) async {
    _notificationFormat = format;
    var arguments = <String, dynamic> {
      'notificationFormat': format
    };
    return await _invokeMethod('setNotificationFormat', arguments);
  }
  bool isActive() {
    return _status != 'UNKNOWN';
  }
  bool isSubscribed() {
    return _status == 'SUBSCRIBED' || _status == 'TRIGGERED';
  }
  bool isTriggered() {
    return _status == 'TRIGGERED';
  }
  String? getActualNotificationFormat() {
    return _actualNotificationFormat;
  }
  String? getActualTriggerExpression() {
    return _actualTrigger;
  }
  String getStatus() {
    return _status;
  }
  int getStatusTimestamp() {
    return _statusTs;
  }
  String? getSubscriptionId() {
    return _subscriptionId;
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["mpnSubId"] = _id;
    return await NativeBridge.instance.invokeMethod('MpnSubscription.$method', arguments);
  }
}