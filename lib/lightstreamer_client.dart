import 'package:lightstreamer_flutter_client/src/native_bridge.dart';
import 'package:lightstreamer_flutter_client/src/client_listeners.dart';

export 'package:lightstreamer_flutter_client/src/client_listeners.dart';

class ConnectionDetails {
  final String _id;
  final NativeBridge _bridge;
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

  ConnectionDetails._(String clientId, NativeBridge bridge) : _id = clientId, _bridge = bridge;

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
    return await _bridge.invokeMethod('ConnectionDetails.$method', arguments);
  }
}

class ConnectionOptions {
  // TODO keep in sync
  final String _id;
  final NativeBridge _bridge;
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

  ConnectionOptions._(String clientId, NativeBridge bridge) : _id = clientId, _bridge = bridge;

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
    return await _bridge.invokeMethod('ConnectionOptions.$method', arguments);
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
    }
  }

  void removeListener(SubscriptionListener listener) {
    _listeners.remove(listener);
  }

  List<SubscriptionListener> getListeners() {
    return _listeners.toList();
  }

  // TODO listeners
  // TODO external int getCommandPosition();
  // TODO external int getKeyPosition();
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
  // TODO bool isActive() {
  // }
  // TODO bool isSubscribed() {
  // }
  // TODO String? getValue(StringOrInt itemNameOrPosition, StringOrInt fieldNameOrPosition) {
  // }
  // TODO String? getCommandValue(StringOrInt itemNameOrPosition, String keyValue, StringOrInt fieldNameOrPosition) {
  // }
}

class LightstreamerClient {
  // TODO move into a singleton
  static int _idGenerator = 0;

  late final String _id;
  final NativeBridge _bridge = NativeBridge.instance;
  late final ConnectionDetails connectionDetails;
  late final ConnectionOptions connectionOptions;
  final List<ClientListener> _listeners = [];

  LightstreamerClient._() : _id = '${_idGenerator++}' {
    connectionDetails = ConnectionDetails._(_id, _bridge);
    connectionOptions = ConnectionOptions._(_id, _bridge);
  }

  // TODO factory method or initialization method?
  static Future<LightstreamerClient> create(String? serverAddress, String? adapterSet) async {
    var client = LightstreamerClient._();
    client._bridge.clientHandler.addClient(client._id, client);

    client.connectionDetails.setServerAddress(serverAddress);
    client.connectionDetails.setAdapterSet(adapterSet);
    var arguments = <String, dynamic>{
      "id": client._id,
      "serverAddress": serverAddress,
      "adapterSet": adapterSet
    };
    await client._bridge.invokeMethod('LightstreamerClient.create', arguments);
    return client;
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
    _bridge.subscriptionHandler.addSubscription(sub._id, sub);
    return await _invokeMethod('subscribe', arguments);
  }

  Future<void> unsubscribe(Subscription sub) async {
    var arguments = <String, dynamic>{
      'subId': sub._id
    };
    _bridge.subscriptionHandler.removeSubscription(sub._id);
    return await _invokeMethod('unsubscribe', arguments);
  }

  Future<List<Subscription>> getSubscriptions() async {
    List<String> subIds = (await _invokeMethod('getSubscriptions')).cast<String>();
    List<Subscription> res = [];
    for (var subId in subIds) {
      var sub = _bridge.subscriptionHandler.getSubscription(subId);
      if (sub != null) {
        res.add(sub);
      }
    }
    return res;
  }

  Future<void> sendMessage(String message, [String? sequence, int? delayTimeout, ClientMessageListener? listener, bool? enqueueWhileDisconnected]) async {
    var arguments = <String, dynamic>{
      'message': message,
      'sequence': sequence,
      'delayTimeout': delayTimeout,
      'enqueueWhileDisconnected': enqueueWhileDisconnected
    };
    if (listener != null) {
      var msgId = _bridge.messageHandler.addListener(listener);
      arguments['msgId'] = msgId;
    }
    return await _invokeMethod('sendMessage', arguments);
  }

  void addListener(ClientListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(ClientListener listener) {
    _listeners.remove(listener);
  }

  List<ClientListener> getListeners() {
    return _listeners.toList();
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = _id;
    return await _bridge.invokeMethod('LightstreamerClient.$method', arguments);
  }
}