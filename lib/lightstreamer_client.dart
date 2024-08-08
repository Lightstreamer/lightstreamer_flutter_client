import 'dart:async';

import 'package:flutter/services.dart';

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
    return await LightstreamerClient._methodChannel.invokeMethod('ConnectionDetails.$method', arguments);
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
    return await LightstreamerClient._methodChannel.invokeMethod('ConnectionOptions.$method', arguments);
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
  static const MethodChannel _methodChannel = MethodChannel('com.lightstreamer.flutter/methods');
  static const MethodChannel _listenerChannel = MethodChannel('com.lightstreamer.flutter/listeners');
  // TODO avoid memory leak
  static Map<String, LightstreamerClient> _clientMap = {};
  static Map<String, Subscription> _subMap = {};
  static int _msgIdGenerator = 0;
  static Map<String, ClientMessageListener> _msgListenerMap = {}; 

  final String _id;
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
    
    // TODO init only one time
    _listenerChannel.setMethodCallHandler(_listenerChannelHandler);
    _clientMap[client._id] = client;

    client.connectionDetails.setServerAddress(serverAddress);
    client.connectionDetails.setAdapterSet(adapterSet);
    var arguments = <String, dynamic>{
      "id": client._id,
      "serverAddress": serverAddress,
      "adapterSet": adapterSet
    };
    await _methodChannel.invokeMethod('LightstreamerClient.create', arguments);
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
    // TODO what if sub is already there?
    _subMap[sub._id] = sub;
    return await _invokeMethod('subscribe', arguments);
  }

  Future<void> unsubscribe(Subscription sub) async {
    var arguments = <String, dynamic>{
      'subId': sub._id
    };
    _subMap.remove(sub._id);
    return await _invokeMethod('unsubscribe', arguments);
  }

  Future<List<Subscription>> getSubscriptions() async {
    List<Object?> subIds = await _invokeMethod('getSubscriptions');
    List<Subscription> res = [];
    for (var subId in subIds) {
      var sub = _subMap[subId];
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
      var msgId = 'msg${_msgIdGenerator++}';
      arguments['msgId'] = msgId;
      _msgListenerMap[msgId] = listener;
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

  static Future<dynamic> _listenerChannelHandler(MethodCall call) {
    // TODO use a logger
    print('event on channel com.lightstreamer.flutter/listeners: ${call.method} ${call.arguments}');
    switch (call.method) {
      case "SubscriptionListener.onItemUpdate":
        _subscriptionListenerOnItemUpdate(call);
      case "SubscriptionListener.onSubscriptionError":
        _subscriptionListenerOnSubscriptionError(call);
      case "SubscriptionListener.onClearSnapshot":
        _subscriptionListenerOnClearSnapshot(call);
      case "SubscriptionListener.onCommandSecondLevelItemLostUpdates":
        _subscriptionListenerOnCommandSecondLevelItemLostUpdates(call);
      case "SubscriptionListener.onCommandSecondLevelSubscriptionError":
        _subscriptionListenerOnCommandSecondLevelSubscriptionError(call);
      case "SubscriptionListener.onEndOfSnapshot":
        _subscriptionListenerOnEndOfSnapshot(call);
      case "SubscriptionListener.onItemLostUpdates":
        _subscriptionListenerOnItemLostUpdate(call);
      case "SubscriptionListener.onSubscription":
        _subscriptionListenerOnSubscription(call);
      case "SubscriptionListener.onUnsubscription":
        _subscriptionListenerOnUnsubscription(call);
      case "SubscriptionListener.onRealMaxFrequency":
        _subscriptionListenerOnRealMaxFrequency(call);
        
      case "ClientListener.onStatusChange":
        _clientListenerOnStatusChange(call);
      case "ClientListener.onPropertyChange":
        _clientListenerOnPropertyChange(call);
      case "ClientListener.onServerError":
        _clientListenerOnServerError(call);

      case "ClientMessageListener.onAbort":
        _messageListenerOnAbort(call);
      case "ClientMessageListener.onDeny":
        _messageListenerOnDeny(call);
      case "ClientMessageListener.onDiscarded":
        _messageListenerOnDiscarded(call);
      case "ClientMessageListener.onError":
        _messageListenerOnError(call);
      case "ClientMessageListener.onProcessed":
        _messageListenerOnProcessed(call);
    }
    return Future.value();
  }

  static void _messageListenerOnAbort(MethodCall call) {
   var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    bool sentOnNetwork = arguments['sentOnNetwork'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onAbort(originalMessage, sentOnNetwork);
    });
  }

  static void _messageListenerOnDeny(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onDeny(originalMessage, errorCode, errorMessage);
    });
  }

  static void _messageListenerOnDiscarded(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onDiscarded(originalMessage);
    });
  }

  static void _messageListenerOnError(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onError(originalMessage);
    });
  }

  static void _messageListenerOnProcessed(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    String response = arguments['response'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onProcessed(originalMessage, response);
    });
  }

  static void _clientListenerOnStatusChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String status = arguments['status'];
    // TODO check null
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client._listeners) {
      scheduleMicrotask(() {
        l.onStatusChange(status);
      });
    }
  }

  static void _clientListenerOnPropertyChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String property = arguments['property'];
    // TODO check null
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client._listeners) {
      scheduleMicrotask(() {
        l.onPropertyChange(property);
      });
    }
  }

  static void _clientListenerOnServerError(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client._listeners) {
      scheduleMicrotask(() {
        l.onServerError(errorCode, errorMessage);
      });
    }
  }

  static void _subscriptionListenerOnClearSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onClearSnapshot(itemName, itemPos);
      });
    }
  }

  static void _subscriptionListenerOnCommandSecondLevelItemLostUpdates(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int lostUpdates = arguments['lostUpdates'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelItemLostUpdates(lostUpdates, key);
      });
    }
  }

  static void _subscriptionListenerOnCommandSecondLevelSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int code = arguments['code'];
    String message = arguments['message'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelSubscriptionError(code, message, key);
      });
    }
  }

  static void _subscriptionListenerOnEndOfSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onEndOfSnapshot(itemName, itemPos);
      });
    }
  }

  static void _subscriptionListenerOnItemLostUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    int lostUpdates = arguments['lostUpdates'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onItemLostUpdates(itemName, itemPos, lostUpdates);
      });
    }
  }

  static void _subscriptionListenerOnItemUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    ItemUpdate update = ItemUpdate._(call);
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onItemUpdate(update);
      });
    }
  }

  static void _subscriptionListenerOnSubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onSubscription();
      });
    }
  }

  static void _subscriptionListenerOnSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onSubscriptionError(errorCode, errorMessage);
      });
    }
  }

  static void _subscriptionListenerOnUnsubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onUnsubscription();
      });
    }
  }

  static void _subscriptionListenerOnRealMaxFrequency(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String? frequency = arguments['frequency'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub._listeners) {
      scheduleMicrotask(() {
        l.onRealMaxFrequency(frequency);
      });
    }
  }

  Future<T> _invokeMethod<T>(String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = _id;
    return await LightstreamerClient._methodChannel.invokeMethod('LightstreamerClient.$method', arguments);
  }
}

interface class ItemUpdate {
  final String? _itemName;
  final int _itemPos;
  final bool _isSnapshot;
  final Map<String, String> _changedFields;
  final Map<String, String> _fields;
  final Map<String, String> _jsonFields;
  final Map<int, String> _changedFieldsByPosition;
  final Map<int, String> _fieldsByPosition;
  final Map<int, String> _jsonFieldsByPosition;

  ItemUpdate._(MethodCall call) :
    _itemName = call.arguments['itemName'],
    _itemPos = call.arguments['itemPos'],
    _isSnapshot = call.arguments['isSnapshot'],
    _changedFields = (call.arguments['changedFields'] as Map<Object?, Object?>).cast(),
    _fields = (call.arguments['fields'].cast() as Map<Object?, Object?>).cast(),
    _jsonFields = (call.arguments['jsonFields'] as Map<Object?, Object?>).cast(),
    _changedFieldsByPosition = (call.arguments['changedFieldsByPosition'] as Map<Object?, Object?>).cast(),
    _fieldsByPosition = (call.arguments['fieldsByPosition'] as Map<Object?, Object?>).cast(),
    _jsonFieldsByPosition = (call.arguments['jsonFieldsByPosition'] as Map<Object?, Object?>).cast();

  String? getItemName() {
    return _itemName;
  }

  int getItemPos() {
    return _itemPos;
  }

  bool isSnapshot() {
    return _isSnapshot;
  }

  String? getValue(String fieldName) {
    return _fields[fieldName];
  }

  String? getValueByPosition(int fieldPosition) {
    return _fieldsByPosition[fieldPosition];
  }

  bool isValueChanged(String fieldName) {
    return _changedFields.containsKey(fieldName);
  }

  bool isValueChangedByPosition(int fieldPosition) {
    return _changedFieldsByPosition.containsKey(fieldPosition);
  }

  String? getValueAsJSONPatchIfAvailable(String fieldName) {
    return _jsonFields[fieldName];
  }

  String? getValueAsJSONPatchIfAvailableByPosition(int fieldPosition) {
    return _jsonFieldsByPosition[fieldPosition];
  }

  Map<String,String> getChangedFields() {
    return {..._changedFields};
  }

  Map<int,String> getChangedFieldsByPosition() {
    return {..._changedFieldsByPosition};
  }

  Map<String,String> getFields() {
    return {..._fields};
  }

  Map<int,String> getFieldsByPosition() {
    return {..._fieldsByPosition};
  }
}

class ClientListener {
  void onStatusChange(String status) {}
  void onPropertyChange(String property) {}
  void onServerError(int errorCode, String errorMessage) {}
  void onListenEnd() {}
  void onListenStart() {}
}

class SubscriptionListener {
  void onClearSnapshot(String itemName, int itemPos) {}
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {}
  void onCommandSecondLevelSubscriptionError(int errorCode, String errorMessage, String key) {}
  void onEndOfSnapshot(String itemName, int itemPos) {}
  void onItemLostUpdates(String itemName, int itemPos, int lostUpdates) {}
  void onItemUpdate(ItemUpdate update) {}
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
  void onRealMaxFrequency(String? frequency) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onUnsubscription() {}
}

class ClientMessageListener {
  void onAbort(String originalMessage, bool sentOnNetwork) {}
  void onDeny(String originalMessage, int errorCode, String errorMessage) {}
  void onDiscarded(String originalMessage) {}
  void onError(String originalMessage) {}
  void onProcessed(String originalMessage, String response) {}
}