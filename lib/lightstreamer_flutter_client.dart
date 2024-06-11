import 'dart:async';

import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'dart:convert';

const MethodChannel _channel = const MethodChannel('com.lightstreamer.lightstreamer_flutter_client.method');
const lightstreamer_clientStatus_channel = BasicMessageChannel<String>('com.lightstreamer.lightstreamer_flutter_client.status', StringCodec());
const lightstreamer_realtime_channel = BasicMessageChannel<String>('com.lightstreamer.lightstreamer_flutter_client.realtime', StringCodec());
const lightstreamer_clientMessage_channel = BasicMessageChannel<String>('com.lightstreamer.lightstreamer_flutter_client.messages', StringCodec());

class LightstreamerFlutterClient {
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
  // itemGroup - String
  // fieldSchema - String
  // NB one of itemList and itemGroup must be specified but not both
  // NB one of fieldList and fieldSchema must be specified but not both
  // optional parameters:
  // dataAdapter - String
  // requestedSnapshot - String
  // requestedBufferSize - int
  // requestedMaxFrequency - String
  // selector - String
  // commandSecondLevelDataAdapter - String
  // commandSecondLevelFields - List<String>
  static Future<String?> subscribe(String mode, {List<String>? itemList, String? itemGroup, List<String>? fieldList, String? fieldSchema, Map<String, String>? parameters}) async {
    final String? status;
    Map<String, Object> arguments = {
      "mode": mode,
    };

    if (itemList == null && itemGroup == null) {
      throw ArgumentError("ItemList and ItemGroup can't be both null");
    }
    if (itemList != null && itemGroup != null) {
      throw ArgumentError("ItemList and ItemGroup can't be both non-null");
    }

    if (fieldList == null && fieldSchema == null) {
      throw ArgumentError("FieldList and FieldSchema can't be both null");
    }
    if (fieldList != null && fieldSchema != null) {
      throw ArgumentError("FieldList and FieldSchema can't be both non-null");
    }

    if (itemList != null) {
      arguments["itemList"] = itemList;
    }
    if (fieldList != null) {
      arguments["fieldList"] = fieldList;
    }
    if (itemGroup != null) {
      arguments["itemGroup"] = itemGroup;
    }
    if (fieldSchema != null) {
      arguments["fieldSchema"] = fieldSchema;
    }
    Map<String, String> params = parameters ?? {};

    if (params.containsKey("dataAdapter")) {
      arguments.putIfAbsent(
          "dataAdapter", () => params.remove("dataAdapter") as Object);
    }

    if (params.containsKey("requestedSnapshot")) {
      arguments.putIfAbsent("requestedSnapshot",
          () => params.remove("requestedSnapshot") as Object);
    }

    if (params.containsKey("requestedBufferSize")) {
      arguments.putIfAbsent("requestedBufferSize",
          () => params.remove("requestedBufferSize") as Object);
    }

    if (params.containsKey("requestedMaxFrequency")) {
      arguments.putIfAbsent("requestedMaxFrequency",
          () => params.remove("requestedMaxFrequency") as Object);
    }

    if (params.containsKey("selector")) {
      arguments.putIfAbsent(
          "selector", () => params.remove("selector") as Object);
    }

    if (params.containsKey("commandSecondLevelDataAdapter")) {
      arguments.putIfAbsent("commandSecondLevelDataAdapter",
          () => params.remove("commandSecondLevelDataAdapter") as Object);
    }

    if (params.containsKey("commandSecondLevelFields")) {
      arguments.putIfAbsent("commandSecondLevelFields",
          () => params.remove("commandSecondLevelFields") as Object);
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

  static void enableLog() {
    _channel.invokeMethod('enableLog');
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

class LightstreamerClient {
  static int _idGenerator = 0;
  static Map<String, Function> _listenerMap = {};
  static Map<String, Function> _subListenerMap = {};

  static int _msgIdGenerator = 0;
  static Map<String, Function> _msgListenerMap = {}; 

  final String _id;

  static void enableLog() {
    _channel.invokeMethod('enableLog');
  }

  LightstreamerClient() : _id = '${_idGenerator++}';

  // mandatory arguments:
  // serverAddress - String
  // adapterSet - String
  // optional parameters:
  // user - String
  // password - String
  Future<String?> connect(String serverAddress, String adapterSet, Map<String, String> parameters) async {
    Map<String, Object> arguments = {
      "id": _id,
      "serverAddress": serverAddress,
      "adapterSet": adapterSet
    };

    if (parameters.containsKey("user")) {
      arguments.putIfAbsent("user", () => parameters.remove("user") as Object);
    }

    if (parameters.containsKey("password")) {
      arguments.putIfAbsent("password", () => parameters.remove("password") as Object);
    }

    if (parameters.containsKey("forcedTransport")) {
      arguments.putIfAbsent("forcedTransport", () => parameters.remove("forcedTransport") as Object);
    }

    if (parameters.containsKey("firstRetryMaxDelay")) {
      arguments.putIfAbsent("firstRetryMaxDelay", () => parameters.remove("firstRetryMaxDelay") as Object);
    }

    if (parameters.containsKey("retryDelay")) {
      arguments.putIfAbsent("retryDelay", () => parameters.remove("retryDelay") as Object);
    }

    if (parameters.containsKey("idleTimeout")) {
      arguments.putIfAbsent("idleTimeout", () => parameters.remove("idleTimeout") as Object);
    }

    if (parameters.containsKey("reconnectTimeout")) {
      arguments.putIfAbsent("reconnectTimeout", () => parameters.remove("reconnectTimeout") as Object);
    }

    if (parameters.containsKey("stalledTimeout")) {
      arguments.putIfAbsent("stalledTimeout", () => parameters.remove("stalledTimeout") as Object);
    }

    if (parameters.containsKey("keepaliveInterval")) {
      arguments.putIfAbsent("keepaliveInterval", () => parameters.remove("keepaliveInterval") as Object);
    }

    if (parameters.containsKey("pollingInterval")) {
      arguments.putIfAbsent("pollingInterval", () => parameters.remove("pollingInterval") as Object);
    }

    if (parameters.containsKey("reverseHeartbeatInterval")) {
      arguments.putIfAbsent("reverseHeartbeatInterval", () => parameters.remove("reverseHeartbeatInterval") as Object);
    }

    if (parameters.containsKey("sessionRecoveryTimeout")) {
      arguments.putIfAbsent("sessionRecoveryTimeout", () => parameters.remove("sessionRecoveryTimeout") as Object);
    }

    if (parameters.containsKey("maxBandwidth")) {
      arguments.putIfAbsent("maxBandwidth", () => parameters.remove("maxBandwidth") as Object);
    }

    if (parameters.containsKey("httpExtraHeaders")) {
      arguments.putIfAbsent("httpExtraHeaders", () => parameters.remove("httpExtraHeaders") as Object);
    }

    if (parameters.containsKey("httpExtraHeadersOnSessionCreationOnly")) {
      arguments.putIfAbsent("httpExtraHeadersOnSessionCreationOnly", () => parameters.remove("httpExtraHeadersOnSessionCreationOnly") as Object);
    }

    if (parameters.containsKey("proxy")) {
      arguments.putIfAbsent("proxy", () => parameters.remove("proxy") as Object);
    }

    final String? status = await _channel.invokeMethod('connect', arguments);

    return status;
  }

  Future<String?> disconnect() async {
    var arguments = { "id": _id };
    final String? status = await _channel.invokeMethod('disconnect', arguments);
    return status;
  }

  Future<String?> getStatus() async {
    var arguments = { "id": _id };
    final String? status = await _channel.invokeMethod('getStatus', arguments);
    return status;
  }

  // mandatory arguments:
  // mode - String (MERGE, DISTINCT, COMMAND, RAW)
  // itemList - List<String>
  // fieldList - List<String>
  // itemGroup - String
  // fieldSchema - String
  // NB one of itemList and itemGroup must be specified but not both
  // NB one of fieldList and fieldSchema must be specified but not both
  // optional parameters:
  // dataAdapter - String
  // requestedSnapshot - String
  // requestedBufferSize - int
  // requestedMaxFrequency - String
  // selector - String
  // commandSecondLevelDataAdapter - String
  // commandSecondLevelFields - List<String>
  Future<String?> subscribe(String mode, {List<String>? itemList, String? itemGroup, List<String>? fieldList, String? fieldSchema, Map<String, String>? parameters}) async {
    final String? status;
    Map<String, Object> arguments = {
      "id": _id,
      "mode": mode,
    };

    if (itemList == null && itemGroup == null) {
      throw ArgumentError("ItemList and ItemGroup can't be both null");
    }
    if (itemList != null && itemGroup != null) {
      throw ArgumentError("ItemList and ItemGroup can't be both non-null");
    }

    if (fieldList == null && fieldSchema == null) {
      throw ArgumentError("FieldList and FieldSchema can't be both null");
    }
    if (fieldList != null && fieldSchema != null) {
      throw ArgumentError("FieldList and FieldSchema can't be both non-null");
    }

    if (itemList != null) {
      arguments["itemList"] = itemList;
    }
    if (fieldList != null) {
      arguments["fieldList"] = fieldList;
    }
    if (itemGroup != null) {
      arguments["itemGroup"] = itemGroup;
    }
    if (fieldSchema != null) {
      arguments["fieldSchema"] = fieldSchema;
    }
    Map<String, String> params = parameters ?? {};

    if (params.containsKey("dataAdapter")) {
      arguments.putIfAbsent("dataAdapter", () => params.remove("dataAdapter") as Object);
    }

    if (params.containsKey("requestedSnapshot")) {
      arguments.putIfAbsent("requestedSnapshot", () => params.remove("requestedSnapshot") as Object);
    }

    if (params.containsKey("requestedBufferSize")) {
      arguments.putIfAbsent("requestedBufferSize", () => params.remove("requestedBufferSize") as Object);
    }

    if (params.containsKey("requestedMaxFrequency")) {
      arguments.putIfAbsent("requestedMaxFrequency", () => params.remove("requestedMaxFrequency") as Object);
    }

    if (params.containsKey("selector")) {
      arguments.putIfAbsent("selector", () => params.remove("selector") as Object);
    }

    if (params.containsKey("commandSecondLevelDataAdapter")) {
      arguments.putIfAbsent("commandSecondLevelDataAdapter", () => params.remove("commandSecondLevelDataAdapter") as Object);
    }

    if (params.containsKey("commandSecondLevelFields")) {
      arguments.putIfAbsent("commandSecondLevelFields", () => params.remove("commandSecondLevelFields") as Object);
    }

    status = await _channel.invokeMethod('subscribe', arguments);

    return status;
  }

  Future<String?> unsubscribe(String subId) async {
    final String? status;

    Map<String, Object> arguments = {
      "id": _id,
      "sub_id": subId,
    };

    status = await _channel.invokeMethod('unsubscribe', arguments);

    return status;
  }

  /// Sets a listener for this client. Removes any existing listener if the value is null.
  void setClientListener(Function? listener) {
    lightstreamer_clientStatus_channel.setMessageHandler(_consumeClientStatus);
    if (listener != null) {
      _listenerMap[_id] = listener;
    } else {
      _listenerMap.remove(_id);
    }
  }

  // shared by all the clients
  static Future<String> _consumeClientStatus(String? message) async {
    try {
      var data = jsonDecode(message!) as Map<String, dynamic>;
      var id = data["id"];
      var value = data["value"];
      var clientListener = _listenerMap[id];

      clientListener?.call(value);
    } catch(e, s) {
      print("ERROR: $e\n$s");
    }
    return "ok";
  }

  /// Sets a listener for this subscription. Removes any existing listener if the value is null.
  void setSubscriptionListener(String subId, Function? subListener) {
    lightstreamer_realtime_channel.setMessageHandler(_consumeRTMessage);
    if (subListener != null) {
      _subListenerMap[subId] = subListener;
    } else {
      _subListenerMap.remove(subId);
    }
  }

  // shared by all the clients
  static Future<String> _consumeRTMessage(String? message) async {
    String currentValue = message as String;

    List<String> l = currentValue.split("|");
    if (l.first == "onItemUpdate") {
      String subId = l[1];
      String item = l[2];
      String fname = l[3];
      String fvalue = l.last;

      _subListenerMap[subId]?.call(item, fname, fvalue);
    }

    return "ok";
  }

  // sendMessage with fire-and-forget behavior
  Future sendMessage(String msg) async {
    sendMessageExt(msg, null, null, null, null);
  }

  Future sendMessageExt(String msg, String? sequence, int? delayTimeout, Function? mlistener, bool? enqueueWhileDisconnected) async {
    bool listnr = false;

    var msgId = "-1";
    if (mlistener != null) {
      lightstreamer_clientMessage_channel.setMessageHandler(_consumeClientMessage);
      msgId = '${_msgIdGenerator++}';
      _msgListenerMap[msgId] = mlistener;
      listnr = true;
    }

    await _channel.invokeMethod('sendMessageExt', {
      "id": _id,
      "msg_id": msgId,
      "message": msg,
      "sequence": sequence,
      "delayTimeout": delayTimeout,
      "listener": listnr,
      "enqueueWhileDisconnected": enqueueWhileDisconnected
    });
  }

  // shared by all the clients
  static Future<String> _consumeClientMessage(String? message) async {
    try {
      var data = jsonDecode(message!) as Map<String, dynamic>;
      var id = data["id"];
      var value = data["value"];
      var msgListener = _msgListenerMap.remove(id);

      msgListener?.call(value);
    } catch(e, s) {
      print("ERROR: $e\n$s");
    }
    return "ok";
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
  Future<String?> mpnSubscribe(String mode, List<String> itemList, List<String> fieldList, Map<String, String> parameters) async {
    final String? status;
    Map<String, Object> arguments = {
      "id": _id,
      "mode": mode,
      "itemList": itemList,
      "fieldList": fieldList
    };

    if (parameters.containsKey("dataAdapter")) {
      arguments.putIfAbsent("dataAdapter", () => parameters.remove("dataAdapter") as Object);
    }

    if (parameters.containsKey("requestedBufferSize")) {
      arguments.putIfAbsent("requestedBufferSize", () => parameters.remove("requestedBufferSize") as Object);
    }

    if (parameters.containsKey("requestedMaxFrequency")) {
      arguments.putIfAbsent("requestedMaxFrequency", () => parameters.remove("requestedMaxFrequency") as Object);
    }

    if (parameters.containsKey("notificationFormat")) {
      arguments.putIfAbsent("notificationFormat", () => parameters.remove("notificationFormat") as Object);
    }

    if (parameters.containsKey("triggerExpression")) {
      arguments.putIfAbsent("triggerExpression", () => parameters.remove("triggerExpression") as Object);
    }

    status = await _channel.invokeMethod('mpnSubscribe', arguments);

    return status;
  }

  Future<String?> mpnUnsubscribe(String subId) async {
    final String? status;

    Map<String, Object> arguments = {
      "id": _id,
      "sub_id": subId,
    };

    status = await _channel.invokeMethod('mpnUnsubscribe', arguments);

    return status;
  }
}