import 'dart:async';
import 'package:flutter/services.dart';

import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';
import 'package:lightstreamer_flutter_client/src/handlers/client_handler.dart';
import 'package:lightstreamer_flutter_client/src/handlers/message_handler.dart';
import 'package:lightstreamer_flutter_client/src/handlers/mpn_device_handler.dart';
import 'package:lightstreamer_flutter_client/src/handlers/subscription_handler.dart';

class NativeBridge {
  static final instance = NativeBridge._();

  // TODO possible memory leak
  final Map<String, LightstreamerClient> _clientMap = {};

  final MethodChannel _methodChannel = const MethodChannel('com.lightstreamer.flutter/methods');
  final MethodChannel _listenerChannel = const MethodChannel('com.lightstreamer.flutter/listeners');

  late final ClientHandler clientHandler;
  final ClientMessageHandler messageHandler = ClientMessageHandler();
  final SubscriptionHandler subscriptionHandler = SubscriptionHandler();
  late final MpnDeviceHandler mpnDeviceHandler;

  NativeBridge._() {
    clientHandler = ClientHandler(this);
    mpnDeviceHandler = MpnDeviceHandler(this);
    _listenerChannel.setMethodCallHandler(_listenerChannelHandler);
  }

  void addClient(String clientId, LightstreamerClient client) {
    _clientMap[clientId] = client;
  }

  LightstreamerClient? getClient(String clientId) {
    return _clientMap[clientId];
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
        clientHandler.handle(method, call);
      case 'SubscriptionListener':
        subscriptionHandler.handle(method, call);
      case 'ClientMessageListener':
        messageHandler.handle(method, call);
      case 'MpnDeviceListener':
        mpnDeviceHandler.handle(method, call);
      default:
        // TODO default
    }
    return Future.value();
  }
}