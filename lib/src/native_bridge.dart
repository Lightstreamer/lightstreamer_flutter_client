// ignore_for_file: non_constant_identifier_names

part of 'client.dart';

class NativeBridge {
  static final instance = NativeBridge._();

  // TODO possible memory leak
  final Map<String, LightstreamerClient> _clientMap = {};

  // TODO possible memory leak
  final Map<String, Subscription> _subMap = {};

  // TODO possible memory leak
  final Map<String, MpnDevice> _mpnDeviceMap = {};

  // TODO possible memory leak (unsubscribeMpnSubscriptions)
  final Map<String, MpnSubscription> _mpnSubMap = {};

  int _msgIdGenerator = 0;
  // TODO possible memory leak
  final Map<String, ClientMessageListener> _msgListenerMap = {};

  final MethodChannel _methodChannel = const MethodChannel('com.lightstreamer.flutter/methods');
  final MethodChannel _listenerChannel = const MethodChannel('com.lightstreamer.flutter/listeners');

  NativeBridge._() {
    _listenerChannel.setMethodCallHandler(_listenerChannelHandler);
  }

  Future<void> client_create(String clientId, LightstreamerClient client, Map<String, dynamic> arguments) async {
    _clientMap[clientId] = client;
    return await invokeMethod('LightstreamerClient.create', arguments);
  }

  Future<void> client_subscribe(String clientId, String subId, Subscription sub, Map<String, dynamic> arguments) async {
    // TODO what if sub is already there?
    _subMap[subId] = sub;
    return await _invokeClientMethod(clientId, 'subscribe', arguments);
  }

  Future<void> client_unsubscribe(String clientId, String subId, Map<String, dynamic> arguments) async {
    // TODO memory leak
    // _subMap.remove(subId);
    return await _invokeClientMethod(clientId, 'unsubscribe', arguments);
  }

  Future<List<Subscription>> client_getSubscriptions(String clientId) async {
    List<String> subIds = (await _invokeClientMethod(clientId, 'getSubscriptions')).cast<String>();
    List<Subscription> res = [];
    for (var subId in subIds) {
      var sub = _subMap[subId];
      if (sub != null) {
        res.add(sub);
      }
    }
    return res;
  }

  Future<void> client_sendMessage(String clientId, ClientMessageListener? listener, Map<String, dynamic> arguments) async {
    if (listener != null) {
      var msgId = 'msg${_msgIdGenerator++}';
      _msgListenerMap[msgId] = listener;
      arguments['msgId'] = msgId;
    }
    return await _invokeClientMethod(clientId, 'sendMessage', arguments);
  }

  Future<void> client_registerForMpn(String clientId, String mpnDevId, MpnDevice device, Map<String, dynamic> arguments) async {
    // TODO what if device is already there?
    _mpnDeviceMap[mpnDevId] = device;
    return await _invokeClientMethod(clientId, 'registerForMpn', arguments);
  }

  Future<void> client_subscribeMpn(String clientId, String mpnSubId, MpnSubscription sub, Map<String, dynamic> arguments) async {
    // TODO what if sub is already there?
    _mpnSubMap[mpnSubId] = sub;
    return await _invokeClientMethod(clientId, 'subscribeMpn', arguments);
  }

  Future<void> client_unsubscribeMpn(String clientId, String mpnSubId, Map<String, dynamic> arguments) async {
    // TODO memory leak
    // _mpnSubMap.remove(mpnSubId);
    return await _invokeClientMethod(clientId, 'unsubscribeMpn', arguments);
  }

  Future<List<MpnSubscription>> client_getMpnSubscriptions(String clientId, Map<String, dynamic> arguments) async {
    List<String> mpnSubIds = (await _invokeClientMethod(clientId, 'getMpnSubscriptions', arguments)).cast<String>();
    List<MpnSubscription> res = [];
    for (var mpnSubId in mpnSubIds) {
      var sub = _mpnSubMap[mpnSubId];
      if (sub != null) {
        res.add(sub);
      }
    }
    return res;
  }

  Future<MpnSubscription?> client_findMpnSubscription(String clientId, Map<String, dynamic> arguments) async {
    String? mpnSubId = await _invokeClientMethod(clientId, 'findMpnSubscription', arguments);
    return mpnSubId == null ? null : _mpnSubMap[mpnSubId];
  }

  Future<T> _invokeClientMethod<T>(String clientId, String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = clientId;
    return await invokeMethod('LightstreamerClient.$method', arguments);
  }

  Future<T> invokeMethod<T>(String method, Map<String, dynamic> arguments) async {
    if (channelLogger.isDebugEnabled()) {
      channelLogger.debug('Invoking $method $arguments');
    }
    return await _methodChannel.invokeMethod(method, arguments);
  }

  Future<dynamic> _listenerChannelHandler(MethodCall call) {
    if (channelLogger.isDebugEnabled()) {
      channelLogger.debug('Accepting ${call.method} ${call.arguments}');
    }
    var [className, method] = call.method.split('.');
    switch (className) {
      case 'ClientListener':
        _ClientListener_handle(method, call);
      case 'SubscriptionListener':
        _SubscriptionListener_handle(method, call);
      case 'ClientMessageListener':
        _ClientMessageListener_handle(method, call);
      case 'MpnDeviceListener':
        _MpnDeviceListener_handle(method, call);
      case 'MpnSubscriptionListener':
        _MpnSubscriptionListener_handle(method, call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
    return Future.value();
  }

  void _ClientListener_handle(String method, MethodCall call) {
    switch (method) {
      case "onStatusChange":
        _ClientListener_onStatusChange(call);
      case "onPropertyChange":
        _ClientListener_onPropertyChange(call);
      case "onServerError":
        _ClientListener_onServerError(call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
  }

  void _ClientListener_onStatusChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String status = arguments['status'];
    runClientListenersAsync(id, (l) => l.onStatusChange(status));
  }

  void _ClientListener_onPropertyChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String property = arguments['property'];
    var client = _clientMap[id];
    if (client != null) {
      switch (property) {
        case "serverInstanceAddress":
          client.connectionDetails._serverInstanceAddress = arguments['value'];
        case "serverSocketName":
          client.connectionDetails._serverSocketName = arguments['value'];
        case "clientIp":
          client.connectionDetails._clientIp = arguments['value'];
        case "sessionId":
          client.connectionDetails._sessionId = arguments['value'];
        case "realMaxBandwidth":
          client.connectionOptions._realMaxBandwidth = arguments['value'];
        case "idleTimeout":
          client.connectionOptions._idleTimeout = arguments['value'];
        case "keepaliveInterval":
          client.connectionOptions._keepaliveInterval = arguments['value'];
        case "pollingInterval":
          client.connectionOptions._pollingInterval = arguments['value'];
      }
    }
    runClientListenersAsync(id, (l) => l.onPropertyChange(property));
  }

  void _ClientListener_onServerError(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    runClientListenersAsync(id, (l) => l.onServerError(errorCode, errorMessage));
  }

  void _ClientMessageListener_handle(String method, MethodCall call) {
    switch (method) {
      case "onAbort":
        _ClientMessageListener_onAbort(call);
      case "onDeny":
        _ClientMessageListener_onDeny(call);
      case "onDiscarded":
        _ClientMessageListener_onDiscarded(call);
      case "onError":
        _ClientMessageListener_onError(call);
      case "onProcessed":
        _ClientMessageListener_onProcessed(call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
  }
  
  void _ClientMessageListener_onAbort(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    bool sentOnNetwork = arguments['sentOnNetwork'];
    runMessageListenersAsync(msgId, (l) => l.onAbort(originalMessage, sentOnNetwork));
  }

  void _ClientMessageListener_onDeny(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    runMessageListenersAsync(msgId, (l) => l.onDeny(originalMessage, errorCode, errorMessage));
  }

  void _ClientMessageListener_onDiscarded(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    runMessageListenersAsync(msgId, (l) => l.onDiscarded(originalMessage));
  }

  void _ClientMessageListener_onError(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    runMessageListenersAsync(msgId, (l) => l.onError(originalMessage));
  }

  void _ClientMessageListener_onProcessed(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    String response = arguments['response'];
    runMessageListenersAsync(msgId, (l) => l.onProcessed(originalMessage, response));
  }

  void _SubscriptionListener_handle(String method, MethodCall call) {
    switch (method) {
      case "onItemUpdate":
        _SubscriptionListener_onItemUpdate(call);
      case "onSubscriptionError":
        _SubscriptionListener_onSubscriptionError(call);
      case "onClearSnapshot":
        _SubscriptionListener_onClearSnapshot(call);
      case "onCommandSecondLevelItemLostUpdates":
        _SubscriptionListener_onCommandSecondLevelItemLostUpdates(call);
      case "onCommandSecondLevelSubscriptionError":
        _SubscriptionListener_onCommandSecondLevelSubscriptionError(call);
      case "onEndOfSnapshot":
        _SubscriptionListener_onEndOfSnapshot(call);
      case "onItemLostUpdates":
        _SubscriptionListener_onItemLostUpdate(call);
      case "onSubscription":
        _SubscriptionListener_onSubscription(call);
      case "onUnsubscription":
        _SubscriptionListener_onUnsubscription(call);
      case "onRealMaxFrequency":
        _SubscriptionListener_onRealMaxFrequency(call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
  }

  void _SubscriptionListener_onClearSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    runSubscriptionListenersAsync(subId, (l) => l.onClearSnapshot(itemName, itemPos));
  }

  void _SubscriptionListener_onCommandSecondLevelItemLostUpdates(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int lostUpdates = arguments['lostUpdates'];
    String key = arguments['key'];
    runSubscriptionListenersAsync(subId, (l) => l.onCommandSecondLevelItemLostUpdates(lostUpdates, key));
  }

  void _SubscriptionListener_onCommandSecondLevelSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int code = arguments['code'];
    String message = arguments['message'];
    String key = arguments['key'];
    runSubscriptionListenersAsync(subId, (l) => l.onCommandSecondLevelSubscriptionError(code, message, key));
  }

  void _SubscriptionListener_onEndOfSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    runSubscriptionListenersAsync(subId, (l) => l.onEndOfSnapshot(itemName, itemPos));
  }

  void _SubscriptionListener_onItemLostUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    int lostUpdates = arguments['lostUpdates'];
    runSubscriptionListenersAsync(subId, (l) => l.onItemLostUpdates(itemName, itemPos, lostUpdates));
  }

  void _SubscriptionListener_onItemUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    ItemUpdate update = ItemUpdate._(call);
    runSubscriptionListenersAsync(subId, (l) => l.onItemUpdate(update));
  }

  void _SubscriptionListener_onSubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    runSubscriptionListenersAsync(subId, (l) => l.onSubscription());
  }

  void _SubscriptionListener_onSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    runSubscriptionListenersAsync(subId, (l) => l.onSubscriptionError(errorCode, errorMessage));
  }

  void _SubscriptionListener_onUnsubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    runSubscriptionListenersAsync(subId, (l) => l.onUnsubscription());
  }

  void _SubscriptionListener_onRealMaxFrequency(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String? frequency = arguments['frequency'];
    runSubscriptionListenersAsync(subId, (l) => l.onRealMaxFrequency(frequency));
  }

  void _MpnDeviceListener_handle(String method, MethodCall call) {
    switch (method) {
      case "onRegistered":
        _MpnDeviceListener_onRegistered(call);
      case "onRegistrationFailed":
        _MpnDeviceListener_onRegistrationFailed(call);
      case "onResumed":
        _MpnDeviceListener_onResumed(call);
      case "onStatusChanged":
        _MpnDeviceListener_onStatusChanged(call);
      case "onSubscriptionsUpdated":
        _MpnDeviceListener_onSubscriptionsUpdated(call);
      case "onSuspended":
        _MpnDeviceListener_onSuspended(call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
  }
  
  void _MpnDeviceListener_onRegistered(MethodCall call) {
    var arguments = call.arguments;
    String mpnDevId = arguments['mpnDevId'];
    var device = _mpnDeviceMap[mpnDevId];
    if (device != null) {
      device._applicationId = arguments['applicationId'];
      device._deviceId = arguments['deviceId'];
      device._deviceToken = arguments['deviceToken'];
      device._platform = arguments['platform'];
      device._previousDeviceToken = arguments['previousDeviceToken'];
    }
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onRegistered());
  }
  
  void _MpnDeviceListener_onRegistrationFailed(MethodCall call) {
    var arguments = call.arguments;
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    String mpnDevId = arguments['mpnDevId'];
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onRegistrationFailed(errorCode, errorMessage));
  }

  void _MpnDeviceListener_onResumed(MethodCall call) {
    var arguments = call.arguments;
    String mpnDevId = arguments['mpnDevId'];
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onResumed());
  }

  void _MpnDeviceListener_onStatusChanged(MethodCall call) {
    var arguments = call.arguments;
    String status = arguments['status'];
    int timestamp = arguments['timestamp'];
    String mpnDevId = arguments['mpnDevId'];
    var device = _mpnDeviceMap[mpnDevId];
    if (device != null) {
      device._status = status;
      device._statusTs = timestamp;
    }
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onStatusChanged(status, timestamp));
  }

  void _MpnDeviceListener_onSubscriptionsUpdated(MethodCall call) {
    var arguments = call.arguments;
    String mpnDevId = arguments['mpnDevId'];
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onSubscriptionsUpdated());
  }

  void _MpnDeviceListener_onSuspended(MethodCall call) {
    var arguments = call.arguments;
    String mpnDevId = arguments['mpnDevId'];
    runMpnDeviceListenersAsync(mpnDevId, (l) => l.onSuspended());
  }

  void _MpnSubscriptionListener_handle(String method, MethodCall call) {
    switch (method) {
      case "onSubscription":
        _MpnSubscriptionListener_onSubscription(call);
      case "onUnsubscription":
        _MpnSubscriptionListener_onUnsubscription(call);
      case "onSubscriptionError":
        _MpnSubscriptionListener_onSubscriptionError(call);
      case "onUnsubscriptionError":
        _MpnSubscriptionListener_onUnsubscriptionError(call);
      case "onTriggered":
        _MpnSubscriptionListener_onTriggered(call);
      case "onStatusChanged":
        _MpnSubscriptionListener_onStatusChanged(call);
      case "onPropertyChanged":
        _MpnSubscriptionListener_onPropertyChanged(call);
      case "onModificationError":
        _MpnSubscriptionListener_onModificationError(call);
      default:
        if (channelLogger.isErrorEnabled()) {
          channelLogger.error("Unknown method ${call.method}", null);
        }
    }
  }

  void _MpnSubscriptionListener_onSubscription(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onSubscription());
  }

  void _MpnSubscriptionListener_onUnsubscription(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onUnsubscription());
  }

  void _MpnSubscriptionListener_onSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onSubscriptionError(errorCode, errorMessage));
  }

  void _MpnSubscriptionListener_onUnsubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onUnsubscriptionError(errorCode, errorMessage));
  }

  void _MpnSubscriptionListener_onTriggered(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onTriggered());
  }

  void _MpnSubscriptionListener_onStatusChanged(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    String status = arguments['status'];
    int timestamp = arguments['timestamp'];
    var sub = _mpnSubMap[mpnSubId];
    if (sub != null) {
      sub._status = status;
      sub._subscriptionId = arguments['subscriptionId'];

    }
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onStatusChanged(status, timestamp));
  }

  void _MpnSubscriptionListener_onPropertyChanged(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
    String property = arguments['property'];
    var sub = _mpnSubMap[mpnSubId];
    if (sub != null) {
      switch (property) {
        case "status_timestamp":
          sub._statusTs = arguments['value'];
        case "mode":
          sub._mode = arguments['value'];
        case "adapter":
          sub._dataAdapter = arguments['value'];
        case "group":
          sub._group = arguments['value'];
        case "schema":
          sub._schema = arguments['value'];
        case "notification_format":
          sub._actualNotificationFormat = arguments['value'];
        case "trigger":
          sub._actualTrigger = arguments['value'];
        case "requested_buffer_size":
          sub._bufferSize = arguments['value'];
        case "requested_max_frequency":
          sub._requestedMaxFrequency = arguments['value'];
      }
    }
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onPropertyChanged(property));
  }

  void _MpnSubscriptionListener_onModificationError(MethodCall call) {
    var arguments = call.arguments;
    String mpnSubId = arguments['mpnSubId'];
     int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    String propertyName = arguments['propertyName'];
    runMpnSubscriptionListenersAsync(mpnSubId, (l) => l.onModificationError(errorCode, errorMessage, propertyName));
  }

  void runClientListenersAsync(String clientId, void Function(ClientListener) cb) {
    var client = _clientMap[clientId];
    if (client == null) {
      if (channelLogger.isErrorEnabled()) {
        channelLogger.error("Unknown LightstreamerClient with id $clientId", null);
      }
      return;
    }
    for (var l in client.getListeners()) {
      scheduleMicrotask(() => cb(l));
    }
  }

  void runMessageListenersAsync(String msgId, void Function(ClientMessageListener) cb) {
    var listener = _msgListenerMap.remove(msgId);
    if (listener == null) {
      if (channelLogger.isErrorEnabled()) {
        channelLogger.error("Unknown ClientMessageListener with id $msgId", null);
      }
      return;
    }
    scheduleMicrotask(() => cb(listener));
  }

  void runSubscriptionListenersAsync(String subId, void Function(SubscriptionListener) cb) {
    var sub = _subMap[subId];
    if (sub == null) {
      if (channelLogger.isErrorEnabled()) {
        channelLogger.error("Unknown Subscription with id $subId", null);
      }
      return;
    }
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() => cb(l));
    }
  }

  void runMpnDeviceListenersAsync(String mpnDevId, void Function(MpnDeviceListener) cb) {
    var device = _mpnDeviceMap[mpnDevId];
    if (device == null) {
       if (channelLogger.isErrorEnabled()) {
        channelLogger.error("No MpnDevice registered with id $mpnDevId", null);
      }
      return;
    }
    for (var l in device.getListeners()) {
      scheduleMicrotask(() => cb(l));
    }
  }

  void runMpnSubscriptionListenersAsync(String mpnSubId, void Function(MpnSubscriptionListener) cb) {
    var sub = _mpnSubMap[mpnSubId];
    if (sub == null) {
      if (channelLogger.isErrorEnabled()) {
        channelLogger.error("Unknown MpnSubscription with id $mpnSubId", null);
      }
      return;
    }
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        scheduleMicrotask(() => cb(l));
      });
    }
  }
}