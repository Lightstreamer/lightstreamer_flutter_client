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

    if (parameters.containsKey("forcedTransport")) {
      arguments.putIfAbsent("forcedTransport",
          () => parameters.remove("forcedTransport") as Object);
    }

    if (parameters.containsKey("firstRetryMaxDelay")) {
      arguments.putIfAbsent("firstRetryMaxDelay",
          () => parameters.remove("firstRetryMaxDelay") as Object);
    }

    if (parameters.containsKey("retryDelay")) {
      arguments.putIfAbsent(
          "retryDelay", () => parameters.remove("retryDelay") as Object);
    }

    if (parameters.containsKey("idleTimeout")) {
      arguments.putIfAbsent(
          "idleTimeout", () => parameters.remove("idleTimeout") as Object);
    }

    if (parameters.containsKey("reconnectTimeout")) {
      arguments.putIfAbsent("reconnectTimeout",
          () => parameters.remove("reconnectTimeout") as Object);
    }

    if (parameters.containsKey("stalledTimeout")) {
      arguments.putIfAbsent("stalledTimeout",
          () => parameters.remove("stalledTimeout") as Object);
    }

    if (parameters.containsKey("keepaliveInterval")) {
      arguments.putIfAbsent("keepaliveInterval",
          () => parameters.remove("keepaliveInterval") as Object);
    }

    if (parameters.containsKey("pollingInterval")) {
      arguments.putIfAbsent("pollingInterval",
          () => parameters.remove("pollingInterval") as Object);
    }

    if (parameters.containsKey("reverseHeartbeatInterval")) {
      arguments.putIfAbsent("reverseHeartbeatInterval",
          () => parameters.remove("reverseHeartbeatInterval") as Object);
    }

    if (parameters.containsKey("sessionRecoveryTimeout")) {
      arguments.putIfAbsent("sessionRecoveryTimeout",
          () => parameters.remove("sessionRecoveryTimeout") as Object);
    }

    if (parameters.containsKey("maxBandwidth")) {
      arguments.putIfAbsent(
          "maxBandwidth", () => parameters.remove("maxBandwidth") as Object);
    }

    if (parameters.containsKey("httpExtraHeaders")) {
      arguments.putIfAbsent("httpExtraHeaders",
          () => parameters.remove("httpExtraHeaders") as Object);
    }

    if (parameters.containsKey("httpExtraHeadersOnSessionCreationOnly")) {
      arguments.putIfAbsent(
          "httpExtraHeadersOnSessionCreationOnly",
          () => parameters.remove("httpExtraHeadersOnSessionCreationOnly")
              as Object);
    }

    if (parameters.containsKey("proxy")) {
      arguments.putIfAbsent(
          "proxy", () => parameters.remove("proxy") as Object);
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
  static Future sendMessageExt(String msg, String? sequence, int? delayTimeout,
      Function? mlistener, bool enqueueWhileDisconnected) async {
    bool listnr = false;

    if (mlistener != null) {
      developer.log("Received mlistener");
      lightstreamer_clientMessage_channel
          .setMessageHandler(_consumeClientMessage);
      messageListener = mlistener;
      listnr = true;
    }

    await _channel.invokeMethod('sendMessageExt', {
      "message": msg,
      "sequence": sequence,
      "delayTimeout": delayTimeout,
      "listener": listnr,
      "enqueueWhileDisconnected": enqueueWhileDisconnected
    });
    return;
  }

  static Future<String> _consumeRTMessage(String? message) async {
    String currentValue = message as String;

    developer.log("Received message: " + currentValue);
    List<String> l = currentValue.split("|");
    if (l.first == "onItemUpdate") {
      String subId = l[1];
      String item = l[2];
      String fname = l[3];
      String fvalue = l.last;

      if (subscriptionListeners.containsKey(subId)) {
        subscriptionListeners[subId]!(item, fname, fvalue);
      }
    } else {
      clientListener!(message);
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
