import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

class ClientMessageHandler {
  int _msgIdGenerator = 0;
  // TODO possible memory leak
  final Map<String, ClientMessageListener> _msgListenerMap = {};

  String addListener(ClientMessageListener listener) {
    var msgId = 'msg${_msgIdGenerator++}';
    _msgListenerMap[msgId] = listener;
    return msgId;
  }

  void handle(String method, MethodCall call) {
    switch (method) {
      case "onAbort":
        _onAbort(call);
      case "onDeny":
        _onDeny(call);
      case "onDiscarded":
        _onDiscarded(call);
      case "onError":
        _onError(call);
      case "onProcessed":
        _onProcessed(call);
      default:
        // TODO default
    }
  }
  
  void _onAbort(MethodCall call) {
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

  void _onDeny(MethodCall call) {
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

  void _onDiscarded(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onDiscarded(originalMessage);
    });
  }

  void _onError(MethodCall call) {
    var arguments = call.arguments;
    String msgId = arguments['msgId'];
    String originalMessage = arguments['originalMessage'];
    // TODO null check
    ClientMessageListener listener = _msgListenerMap.remove(msgId)!;
    scheduleMicrotask(() {
      listener.onError(originalMessage);
    });
  }

  void _onProcessed(MethodCall call) {
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
}
