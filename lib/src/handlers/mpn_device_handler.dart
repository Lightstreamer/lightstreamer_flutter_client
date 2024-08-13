import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/src/native_bridge.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

class MpnDeviceHandler {
  final NativeBridge _bridge;

  MpnDeviceHandler(NativeBridge bridge) : _bridge = bridge;

  void handle(String method, MethodCall call) {
    switch (method) {
      case "onRegistered":
        _onRegistered(call);
      case "onRegistrationFailed":
        _onRegistrationFailed(call);
      case "onResumed":
        _onResumed(call);
      case "onStatusChanged":
        _onStatusChanged(call);
      case "onSubscriptionsUpdated":
        _onSubscriptionsUpdated(call);
      case "onSuspended":
        _onSuspended(call);
      default:
        // TODO default
    }
  }
  
  void _onRegistered(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onRegistered();
        });
      }
    }
  }
  
  void _onRegistrationFailed(MethodCall call) {
    var arguments = call.arguments;
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onRegistrationFailed(errorCode, errorMessage);
        });
      }
    }
  }

  void _onResumed(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onResumed();
        });
      }
    }
  }

  void _onStatusChanged(MethodCall call) {
    var arguments = call.arguments;
    String status = arguments['status'];
    int timestamp = arguments['timestamp'];
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onStatusChanged(status, timestamp);
        });
      }
    }
  }

  void _onSubscriptionsUpdated(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
    var listeners = client.getMpnDevice()?.getListeners();
    if (listeners != null) {
      for (var l in listeners) {
        scheduleMicrotask(() {
          l.onSubscriptionsUpdated();
        });
      }
    }
  }

  void _onSuspended(MethodCall call) {
    var arguments = call.arguments;
    String id = arguments['id'];
    // TODO null check
    LightstreamerClient client = _bridge.getClient(id)!;
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