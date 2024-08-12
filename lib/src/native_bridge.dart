import 'dart:async';
import 'package:flutter/services.dart';

import 'package:lightstreamer_flutter_client/src/handlers/client_handler.dart';
import 'package:lightstreamer_flutter_client/src/handlers/message_handler.dart';
import 'package:lightstreamer_flutter_client/src/handlers/subscription_handler.dart';

class NativeBridge {
  static final instance = NativeBridge._();

  final MethodChannel _methodChannel = const MethodChannel('com.lightstreamer.flutter/methods');
  final MethodChannel _listenerChannel = const MethodChannel('com.lightstreamer.flutter/listeners');
  final ClientHandler clientHandler = ClientHandler();
  final ClientMessageHandler messageHandler = ClientMessageHandler();
  final SubscriptionHandler subscriptionHandler = SubscriptionHandler();

  NativeBridge._() {
    _listenerChannel.setMethodCallHandler(_listenerChannelHandler);
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
      default:
        // TODO default
    }
    return Future.value();
  }
}