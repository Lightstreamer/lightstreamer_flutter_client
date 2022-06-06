import 'dart:async';

import 'dart:developer' as developer;

import 'package:flutter/services.dart';

class LightstreamerFlutterClient {
  static const MethodChannel _channel = const MethodChannel(
      'com.lightstreamer.lightstreamer_flutter_client.method');

  static const lightstreamer_clientStatus_channel = BasicMessageChannel<String>(
      'com.lightstreamer.lightstreamer_flutter_client.status', StringCodec());

  static const lightstreamer_realtime_channel = BasicMessageChannel<String>(
      'com.lightstreamer.lightstreamer_flutter_client.realtime', StringCodec());

  static const lightstreamer_clientMessage_channel =
      BasicMessageChannel<String>(
          'com.lightstreamer.lightstreamer_flutter_client.messages',
          StringCodec());

  static Map<String, Function> subscriptionListeners = {};

  static Function? clientListener;

  static Function? messageListener;

  // mandatory arguments:
  // serverAddress - String
  // adapterSet - String
  // optional parameters:
  // user - String
  // password - String
  static Future<String?> connect(String serverAddress, String adapterSet,
      Map<String, String> parameters) async {
    Map<String, Object> arguments = {
      "serverAddress": serverAddress,
      "adapterSet": adapterSet
    };

    if (parameters.containsKey("user")) {
      arguments.putIfAbsent("user", () => parameters.remove("user") as Object);
    }

    if (parameters.containsKey("password")) {
      arguments.putIfAbsent(
          "password", () => parameters.remove("password") as Object);
    }

    final String? status = await _channel.invokeMethod('connect', arguments);

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

  // mandatory arguments:
  // mode - String (MERGE, DISTINCT, COMMAND, RAW)
  // itemList - List<String>
  // fieldList - List<String>
  // optional parameters:
  // dataAdapter - String
  // requestedSnapshot - String
  // requestedBufferSize - int
  // requestedMaxFrequency - String
  // selector - String
  // commandSecondLevelDataAdapter - String
  // commandSecondLevelFields - List<String>
  static Future<String?> subscribe(String mode, List<String> itemList,
      List<String> fieldList, Map<String, String> parameters) async {
    final String? status;
    Map<String, Object> arguments = {
      "mode": mode,
      "itemList": itemList,
      "fieldList": fieldList
    };

    if (parameters.containsKey("dataAdapter")) {
      arguments.putIfAbsent(
          "dataAdapter", () => parameters.remove("dataAdapter") as Object);
    }

    if (parameters.containsKey("requestedSnapshot")) {
      arguments.putIfAbsent("requestedSnapshot",
          () => parameters.remove("requestedSnapshot") as Object);
    }

    if (parameters.containsKey("requestedBufferSize")) {
      arguments.putIfAbsent("requestedBufferSize",
          () => parameters.remove("requestedBufferSize") as Object);
    }

    if (parameters.containsKey("requestedMaxFrequency")) {
      arguments.putIfAbsent("requestedMaxFrequency",
          () => parameters.remove("requestedMaxFrequency") as Object);
    }

    if (parameters.containsKey("selector")) {
      arguments.putIfAbsent(
          "selector", () => parameters.remove("selector") as Object);
    }

    if (parameters.containsKey("commandSecondLevelDataAdapter")) {
      arguments.putIfAbsent("commandSecondLevelDataAdapter",
          () => parameters.remove("commandSecondLevelDataAdapter") as Object);
    }

    if (parameters.containsKey("commandSecondLevelFields")) {
      arguments.putIfAbsent("commandSecondLevelFields",
          () => parameters.remove("commandSecondLevelFields") as Object);
    }

    status = await _channel.invokeMethod('subscribe', arguments);

    return status;
  }

  // mandatory arguments:
  // mode - String (MERGE, DISTINCT, COMMAND, RAW)
  // itemList - List<String>
  // fieldList - List<String>
  // optional parameters:
  // dataAdapter - String
  // requestedBufferSize - int
  // requestedMaxFrequency - String
  // notificationFormat - String
  static Future<String?> mpnSubscribe(String mode, List<String> itemList,
      List<String> fieldList, Map<String, String> parameters) async {
    final String? status;
    Map<String, Object> arguments = {
      "mode": mode,
      "itemList": itemList,
      "fieldList": fieldList
    };

    if (parameters.containsKey("dataAdapter")) {
      arguments.putIfAbsent(
          "dataAdapter", () => parameters.remove("dataAdapter") as Object);
    }

    if (parameters.containsKey("requestedBufferSize")) {
      arguments.putIfAbsent("requestedBufferSize",
          () => parameters.remove("requestedBufferSize") as Object);
    }

    if (parameters.containsKey("requestedMaxFrequency")) {
      arguments.putIfAbsent("requestedMaxFrequency",
          () => parameters.remove("requestedMaxFrequency") as Object);
    }

    if (parameters.containsKey("notificationFormat")) {
      arguments.putIfAbsent("notificationFormat",
          () => parameters.remove("notificationFormat") as Object);
    }

    if (parameters.containsKey("triggerExpression")) {
      arguments.putIfAbsent("triggerExpression",
          () => parameters.remove("triggerExpression") as Object);
    }

    status = await _channel.invokeMethod('mpnSubscribe', arguments);

    return status;
  }

  static void setClientListener(Function listener) {
    lightstreamer_clientStatus_channel.setMessageHandler(_consumeClientStatus);

    clientListener = listener;
  }

  static void setSubscriptionListener(String subId, Function subListener) {
    if (subscriptionListeners.isEmpty) {
      lightstreamer_realtime_channel.setMessageHandler(_consumeRTMessage);
    }

    subscriptionListeners.putIfAbsent(subId, () => subListener);
  }

  static Future<String?> unsubscribe(String subId) async {
    final String? status;

    Map<String, Object> arguments = {
      "sub_id": subId,
    };

    status = await _channel.invokeMethod('unsubscribe', arguments);

    return status;
  }

  static Future<String?> mpnUnsubscribe(String subId) async {
    final String? status;

    Map<String, Object> arguments = {
      "sub_id": subId,
    };

    status = await _channel.invokeMethod('mpnUnsubscribe', arguments);

    return status;
  }

  // sendMessage with fire-and-forget behavior
  static Future sendMessage(String msg) async {
    await _channel.invokeMethod('sendMessage', {"message": msg});
    return;
  }

  // sendMessage extended version
  static Future sendMessageExt(String msg, String sequence, int delayTimeout,
      Function mlistener, bool enqueueWhileDisconnected) async {
    lightstreamer_clientMessage_channel
        .setMessageHandler(_consumeClientMessage);

    messageListener = mlistener;

    await _channel.invokeMethod('sendMessageExt', {
      "message": msg,
      "sequence": sequence,
      "delayTimeout": delayTimeout,
      "listener": true,
      "enqueueWhileDisconnected": enqueueWhileDisconnected
    });
    return;
  }

  static Future<String> _consumeRTMessage(String? message) async {
    String currentValue = message as String;

    developer.log("Received message: " + currentValue);
    List<String> l = currentValue.split("|");
    String subId = l.first;
    String item = l[1];
    String fname = l[2];
    String fvalue = l.last;

    if (subscriptionListeners.containsKey(subId)) {
      subscriptionListeners[subId]!(item, fname, fvalue);
    }

    return "ok";
  }

  static Future<String> _consumeClientStatus(String? message) async {
    String currentMessage = message as String;

    developer.log("Received message: " + currentMessage);

    clientListener!(message);

    return "ok";
  }

  static Future<String> _consumeClientMessage(String? message) async {
    String currentMessage = message as String;

    developer.log("Received message client: " + currentMessage);

    messageListener!(message);

    return "ok";
  }
}
