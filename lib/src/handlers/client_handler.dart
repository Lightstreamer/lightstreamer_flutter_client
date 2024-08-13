import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import 'package:lightstreamer_flutter_client/src/native_bridge.dart';

class ClientHandler {
  final NativeBridge _bridge;

  ClientHandler(NativeBridge bridge) : _bridge = bridge;

  void handle(String method, MethodCall call) {
    switch (method) {
      case "onStatusChange":
        _onStatusChange(call);
      case "onPropertyChange":
        _onPropertyChange(call);
      case "onServerError":
        _onServerError(call);
      default:
        // TODO default
    }
  }

  void _onStatusChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String status = arguments['status'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onStatusChange(status);
      });
    }
  }

  void _onPropertyChange(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    String property = arguments['property'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onPropertyChange(property);
      });
    }
  }

  void _onServerError(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    for (var l in client.getListeners()) {
      scheduleMicrotask(() {
        l.onServerError(errorCode, errorMessage);
      });
    }
  }
}