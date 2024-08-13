// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

class NativeBridge {
  static final instance = NativeBridge._();

  // TODO possible memory leak
  final Map<String, LightstreamerClient> _clientMap = {};

  // TODO possible memory leak
  final Map<String, Subscription> _subMap = {};

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
    _subMap.remove(subId);
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

  Future<T> _invokeClientMethod<T>(String clientId, String method, [ Map<String, dynamic>? arguments ]) async {
    arguments = arguments ?? {};
    arguments["id"] = clientId;
    return await invokeMethod('LightstreamerClient.$method', arguments);
  }

  Future<T> invokeMethod<T>(String method, Map<String, dynamic> arguments) async {
    return await _methodChannel.invokeMethod(method, arguments);
  }

  Future<dynamic> _listenerChannelHandler(MethodCall call) {
    // TODO use a logger
    print('event on channel com.lightstreamer.flutter/listeners: ${call.method} ${call.arguments}');
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
      default:
        // TODO default
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
        // TODO default
    }
  }

  void _ClientListener_onStatusChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String status = arguments['status'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onStatusChange(status);
      });
    }
  }

  void _ClientListener_onPropertyChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String property = arguments['property'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onPropertyChange(property);
      });
    }
  }

  void _ClientListener_onServerError(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onServerError(errorCode, errorMessage);
      });
    }
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
        // TODO default
    }
  }
  
  void _ClientMessageListener_onAbort(MethodCall call) {
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

  void _ClientMessageListener_onDeny(MethodCall call) {
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

  void _ClientMessageListener_onDiscarded(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onDiscarded(originalMessage);
    });
  }

  void _ClientMessageListener_onError(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onError(originalMessage);
    });
  }

  void _ClientMessageListener_onProcessed(MethodCall call) {
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
        // TODO default
    }
  }

  void _SubscriptionListener_onClearSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onClearSnapshot(itemName, itemPos);
      });
    }
  }

  void _SubscriptionListener_onCommandSecondLevelItemLostUpdates(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int lostUpdates = arguments['lostUpdates'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelItemLostUpdates(lostUpdates, key);
      });
    }
  }

  void _SubscriptionListener_onCommandSecondLevelSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int code = arguments['code'];
    String message = arguments['message'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelSubscriptionError(code, message, key);
      });
    }
  }

  void _SubscriptionListener_onEndOfSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onEndOfSnapshot(itemName, itemPos);
      });
    }
  }

  void _SubscriptionListener_onItemLostUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    int lostUpdates = arguments['lostUpdates'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onItemLostUpdates(itemName, itemPos, lostUpdates);
      });
    }
  }

  void _SubscriptionListener_onItemUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    ItemUpdate update = ItemUpdate(call);
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onItemUpdate(update);
      });
    }
  }

  void _SubscriptionListener_onSubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onSubscription();
      });
    }
  }

  void _SubscriptionListener_onSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onSubscriptionError(errorCode, errorMessage);
      });
    }
  }

  void _SubscriptionListener_onUnsubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onUnsubscription();
      });
    }
  }

  void _SubscriptionListener_onRealMaxFrequency(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String? frequency = arguments['frequency'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onRealMaxFrequency(frequency);
      });
    }
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
        // TODO default
    }
  }
  
  void _MpnDeviceListener_onRegistered(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onRegistered();
        });
      }
    }
  }
  
  void _MpnDeviceListener_onRegistrationFailed(MethodCall call) {
    var arguments = call.arguments;
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onRegistrationFailed(errorCode, errorMessage);
        });
      }
    }
  }

  void _MpnDeviceListener_onResumed(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onResumed();
        });
      }
    }
  }

  void _MpnDeviceListener_onStatusChanged(MethodCall call) {
    var arguments = call.arguments;
    String status = arguments['status'];
    int timestamp = arguments['timestamp'];
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onStatusChanged(status, timestamp);
        });
      }
    }
  }

  void _MpnDeviceListener_onSubscriptionsUpdated(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onSubscriptionsUpdated();
        });
      }
    }
  }

  void _MpnDeviceListener_onSuspended(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _clientMap[id]!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onSuspended();
        });
      }
    }
  }
}