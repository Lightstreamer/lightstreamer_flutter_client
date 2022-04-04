import 'dart:async';

import 'package:flutter/services.dart';

class LightstreamerFlutterClient {
  static const MethodChannel _channel =
      const MethodChannel('lightstreamer_flutter_client');

  static Future<String?> connect(
      String serverAddress, String adapterSet) async {
    final String? status = await _channel.invokeMethod(
        'connect', {"serverAddress": serverAddress, "adapterSet": adapterSet});
    return status;
  }

  static Future<String?> disconnect() async {
    final String? status = await _channel.invokeMethod('disconnect');
    return status;
  }

  static Future<String?> getStatus() async {
    final String? status = await _channel.invokeMethod('getStatus');
    return status;
  }

  // args, mandatory :
  // mode - String (MERGE, DISTINCT, COMMAND, RAW)
  // itemList - List<String>
  // fieldList - List<String>
  // parameters, optional :
  // dataAdapter - String
  static Future<String?> subscribe(String mode, List<String> itemList,
      List<String> fieldList, Map<String, String> parameters) async {
    final String? status;
    if (parameters.containsKey("dataAdapter")) {
      status = await _channel.invokeMethod('subscribe', {
        "mode": mode,
        "itemList": itemList,
        "fieldList": fieldList,
        "dataAdapter": parameters.remove("dataAdapter")
      });
    } else {
      status = await _channel.invokeMethod('subscribe',
          {"mode": mode, "itemList": itemList, "fieldList": fieldList});
    }

    return status;
  }

  static Future sendMessage(String msg) async {
    await _channel.invokeMethod('sendMessage', {"message": msg});
    return;
  }

  static Future sendMessageExt(String msg, String sequence, int delayTimeout,
      bool listener, bool enqueueWhileDisconnected) async {
    await _channel.invokeMethod('sendMessage', {
      "message": msg,
      "sequence": sequence,
      "delayTimeout": delayTimeout,
      "listener": listener,
      "enqueueWhileDisconnected": enqueueWhileDisconnected
    });
    return;
  }
}
