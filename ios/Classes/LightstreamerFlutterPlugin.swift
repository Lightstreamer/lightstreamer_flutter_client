import Foundation
import Flutter
import UIKit
import LightstreamerClient
import os.log

/**
 * A plugin manages the communication between the Flutter component (the Flutter app targeting iOS using the Lightstreamer Flutter Client SDK)
 * and this iOS component (the environment running the Lightstreamer iOS Client SDK
 * that performs the operations requested by the Flutter component).
 * See also: https://docs.flutter.dev/platform-integration/platform-channels
 */
public class LightstreamerFlutterPlugin: NSObject, FlutterPlugin {
  
  let channelLogger = LogManager.getLogger("lightstreamer.flutter")
  
  // TODO potential memory leak: objects are added to the maps but never removed
  
  /**
   * Maps a clientId (i.e. the `id` field of a MethodCall object) to a LightstreamerClient.
   * The mapping is created when any LightstreamerClient method is called by the Flutter component.
   */
  var _clientMap = [String:LightstreamerClient]();
  /**
   * Maps a subId (i.e. the `subId` field of a MethodCall object) to a Subscription.
   * The mapping is created when `LightstreamerClient.subscribe` is called.
   */
  var _subMap = [String:Subscription]();
  
  /**
   * The channel through which the procedure calls requested by the Flutter component are received.
   */
  let _methodChannel: FlutterMethodChannel;
  /**
   * The channel through which the events fired by the listeners are communicated to the Flutter component.
   */
  let _listenerChannel: FlutterMethodChannel;
  
  init(_ registrar: FlutterPluginRegistrar) {
    _methodChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/methods", binaryMessenger: registrar.messenger());
    _listenerChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/listeners", binaryMessenger: registrar.messenger());
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LightstreamerFlutterPlugin(registrar)
    registrar.addMethodCallDelegate(instance, channel: instance._methodChannel)
  }
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (channelLogger.isDebugEnabled) {
      channelLogger.debug("Accepting " + call.method + " " + call.arguments.debugDescription);
    }
    do {
      let parts = call.method.components(separatedBy: ".")
      let className = parts[0]
      let methodName = parts[1]
      switch (className) {
      case "LightstreamerClient":
        try Client_handle(methodName, call, result);
      case "ConnectionDetails":
        try ConnectionDetails_handle(methodName, call, result);
      case "ConnectionOptions":
        try ConnectionOptions_handle(methodName, call, result);
      case "Subscription":
        try Subscription_handle(methodName, call, result);
      // TODO ...
      default:
        if (channelLogger.isErrorEnabled) {
          channelLogger.error("Unknown method " + call.method);
        }
        result(FlutterMethodNotImplemented)
      }
    } catch let e {
      if (channelLogger.isErrorEnabled) {
        channelLogger.error(e.localizedDescription, withException: e);
      }
        result(FlutterError(code: "Lightstreamer Internal Error", message: e.localizedDescription, details: nil))
    }
  }
  
  func Client_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "create":
      try Client_create(call, result);
    case "connect":
      try Client_connect(call, result);
    case "disconnect":
      try Client_disconnect(call, result);
    case "getStatus":
      try Client_getStatus(call, result);
    case "subscribe":
      try Client_subscribe(call, result);
    case "unsubscribe":
      try Client_unsubscribe(call, result);
    case "getSubscriptions":
      try Client_getSubscriptions(call, result);
    case "sendMessage":
      try Client_sendMessage(call, result);
//    case "registerForMpn":
//      Client_registerForMpn(call, result);
//      break;
//    case "subscribeMpn":
//      Client_subscribeMpn(call, result);
//      break;
//    case "unsubscribeMpn":
//      Client_unsubscribeMpn(call, result);
//      break;
//    case "unsubscribeMpnSubscriptions":
//      Client_unsubscribeMpnSubscriptions(call, result);
//      break;
//    case "getMpnSubscriptions":
//      Client_getMpnSubscriptions(call, result);
//      break;
//    case "findMpnSubscription":
//      Client_findMpnSubscription(call, result);
//      break;
    case "setLoggerProvider":
      Client_setLoggerProvider(call, result);
    case "addCookies":
      Client_addCookies(call, result);
    case "getCookies":
      Client_getCookies(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented)
    }
  }
  
  func ConnectionDetails_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "setServerAddress":
      try Details_setServerAddress(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented)
    }
  }
  
  func ConnectionOptions_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "setForcedTransport":
      try ConnectionOptions_setForcedTransport(call, result);
    case "setRequestedMaxBandwidth":
      try ConnectionOptions_setRequestedMaxBandwidth(call, result);
    case "setReverseHeartbeatInterval":
      try ConnectionOptions_setReverseHeartbeatInterval(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented)
    }
  }
  
  func Subscription_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "getCommandPosition":
      try Subscription_getCommandPosition(call, result);
    case "getKeyPosition":
      try Subscription_getKeyPosition(call, result);
    case "setRequestedMaxFrequency":
      try Subscription_setRequestedMaxFrequency(call, result);
    case "isActive":
      try Subscription_isActive(call, result);
    case "isSubscribed":
      try Subscription_isSubscribed(call, result);
    case "getValueByItemNameAndFieldName":
      try Subscription_getValueByItemNameAndFieldName(call, result);
    case "getValueByItemNameAndFieldPos":
      try Subscription_getValueByItemNameAndFieldPos(call, result);
    case "getValueByItemPosAndFieldName":
      try Subscription_getValueByItemPosAndFieldName(call, result);
    case "getValueByItemPosAndFieldPos":
      try Subscription_getValueByItemPosAndFieldPos(call, result);
    case "getCommandValueByItemNameAndFieldName":
      try Subscription_getCommandValueByItemNameAndFieldName(call, result);
    case "getCommandValueByItemNameAndFieldPos":
      try Subscription_getCommandValueByItemNameAndFieldPos(call, result);
    case "getCommandValueByItemPosAndFieldName":
      try Subscription_getCommandValueByItemPosAndFieldName(call, result);
    case "getCommandValueByItemPosAndFieldPos":
      try Subscription_getCommandValueByItemPosAndFieldPos(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented)
    }
  }
  
  func createClient(_ call: FlutterMethodCall) throws -> LightstreamerClient {
    let id: String = call.argument("id");
    let ls_: LightstreamerClient? = _clientMap.get(id);
    if (ls_ != nil) {
      let errMsg = "LightstreamerClient " + id + " already exists";
      if (channelLogger.isErrorEnabled) {
        channelLogger.error(errMsg);
      }
      throw IllegalStateException(errMsg);
    }
    let serverAddress: String? = call.argument("serverAddress");
    let adapterSet: String? = call.argument("adapterSet");
    let ls = LightstreamerClient(serverAddress: serverAddress, adapterSet: adapterSet);
    _clientMap.put(id, ls);
    return ls;
  }
  
  func getClient(_ call: FlutterMethodCall) throws -> LightstreamerClient {
    let id: String = call.argument("id");
    let ls: LightstreamerClient? = _clientMap.get(id);
    if (ls == nil) {
      let errMsg = "A LightstreamerClient wit id " + id + " doesn't exist";
      if (channelLogger.isErrorEnabled) {
        channelLogger.error(errMsg);
      }
      throw IllegalStateException(errMsg);
    }
    return ls!;
  }
  
  func Client_create(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try createClient(call);
    let id: String = call.argument("id");
    client.addDelegate(MyClientListener_(id, client, self));
    result(nil);
  }
  
  func Client_setLoggerProvider(_ call: FlutterMethodCall, _ result: FlutterResult) {
    let level: Int = call.argument("level")
    let level_ = switch (level) {
    case  0: ConsoleLogLevel.trace
    case 10: ConsoleLogLevel.debug
    case 20: ConsoleLogLevel.info
    case 30: ConsoleLogLevel.warn
    case 40: ConsoleLogLevel.error
    case 50: ConsoleLogLevel.fatal
    default: ConsoleLogLevel.error
    }
    LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(level: level_));
    result(nil);
  }
  
  func Client_addCookies(_ call: FlutterMethodCall, _ result: FlutterResult) {
    // TODO
  }
  
  func Client_getCookies(_ call: FlutterMethodCall, _ result: FlutterResult) {
    // TODO
  }
  
  func Client_connect(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let details: [String:Any?] = call.argument("connectionDetails");
    client.connectionDetails.adapterSet = details.get("adapterSet") as? String;
    client.connectionDetails.serverAddress = details.get("serverAddress") as? String;
    client.connectionDetails.user = details.get("user") as? String;
    client.connectionDetails.setPassword(details.get("password") as? String);
    let options: [String:Any?] = call.argument("connectionOptions");
    client.connectionOptions.contentLength = options.get("contentLength") as! UInt64;
    client.connectionOptions.firstRetryMaxDelay = options.get("firstRetryMaxDelay") as! Int;
    let ft: String? = options.get("forcedTransport") as? String;
    client.connectionOptions.forcedTransport = toTransportSelection(ft);
    client.connectionOptions.HTTPExtraHeaders = options.get("httpExtraHeaders") as? [String : String];
    client.connectionOptions.idleTimeout = options.get("idleTimeout") as! Int;
    client.connectionOptions.keepaliveInterval = options.get("keepaliveInterval") as! Int;
    client.connectionOptions.pollingInterval = options.get("pollingInterval") as! Int;
    client.connectionOptions.reconnectTimeout = options.get("reconnectTimeout") as! Int;
    let bwt: String = options.get("requestedMaxBandwidth") as! String;
    client.connectionOptions.requestedMaxBandwidth = toMaxBandwidth(bwt);
    client.connectionOptions.retryDelay = options.get("retryDelay") as! Int;
    client.connectionOptions.reverseHeartbeatInterval = options.get("reverseHeartbeatInterval") as! Int;
    client.connectionOptions.sessionRecoveryTimeout = options.get("sessionRecoveryTimeout") as! Int;
    client.connectionOptions.stalledTimeout = options.get("stalledTimeout") as! Int;
    client.connectionOptions.HTTPExtraHeadersOnSessionCreationOnly = options.get("httpExtraHeadersOnSessionCreationOnly") as! Bool;
    client.connectionOptions.serverInstanceAddressIgnored = options.get("serverInstanceAddressIgnored") as! Bool;
    client.connectionOptions.slowingEnabled = options.get("slowingEnabled") as! Bool;
    client.connect();
    result(nil);
  }
  
  func Client_disconnect(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    client.disconnect();
    result(nil);
  }
  
  func Client_getStatus(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let res = client.status;
    result(res.rawValue);
  }
  
  func Client_subscribe(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let options: [String:Any?] = call.argument("subscription");
    let subId = options.get("id") as! String;
    let items = options.get("items") as? [String];
    let fields = options.get("fields") as? [String];
    let group = options.get("group") as? String;
    let schema = options.get("schema") as? String;
    let dataAdapter = options.get("dataAdapter") as? String;
    let bufferSize = options.get("bufferSize") as? String;
    let snapshot = options.get("snapshot") as? String;
    let requestedMaxFrequency = options.get("requestedMaxFrequency") as? String;
    let selector = options.get("selector") as? String;
    let dataAdapter2 = options.get("dataAdapter2") as? String;
    let fields2 = options.get("fields2") as? [String];
    let schema2 = options.get("schema2") as? String;
    var sub: Subscription! = _subMap.get(subId);
    if (sub == nil) {
      let mode = options.get("mode") as! String
      sub = Subscription(subscriptionMode: Subscription.Mode(rawValue: mode)!);
      sub.addDelegate(MySubscriptionListener(subId, sub, self));
      _subMap.put(subId, sub);
    }
    if (sub.isActive) {
      throw IllegalStateException("Cannot subscribe to an active Subscription");
    }
    if (items != nil) {
      sub.items = items;
    }
    if (fields != nil) {
      sub.fields = fields;
    }
    if (group != nil) {
      sub.itemGroup = group;
    }
    if (schema != nil) {
      sub.fieldSchema = schema;
    }
    if (dataAdapter != nil) {
      sub.dataAdapter = dataAdapter;
    }
    if (bufferSize != nil) {
      sub.requestedBufferSize = toBufferSize(bufferSize);
    }
    if (snapshot != nil) {
      sub.requestedSnapshot = toSnapshot(snapshot);
    }
    if (requestedMaxFrequency != nil) {
      sub.requestedMaxFrequency = toMaxFrequency(requestedMaxFrequency);
    }
    if (selector != nil) {
      sub.selector = selector;
    }
    if (dataAdapter2 != nil) {
      sub.commandSecondLevelDataAdapter = dataAdapter2;
    }
    if (fields2 != nil) {
      sub.commandSecondLevelFields = fields2;
    }
    if (schema2 != nil) {
      sub.commandSecondLevelFieldSchema = schema2;
    }
    client.subscribe(sub);
    result(nil);
  }
  
  func Client_unsubscribe(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    client.unsubscribe(sub);
    result(nil);
  }
  
  func Client_getSubscriptions(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    // TODO improve performance
    let client = try getClient(call);
    let subs = client.subscriptions;
    var res = [String]();
    for (key, value) in _subMap {
      if (subs.contains(where: { $0 === value })) {
        res.append(key);
      }
    }
    result(res);
  }
  
  func Client_sendMessage(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let msgId: String? = call.argumentOrNull("msgId");
    let message: String = call.argument("message");
    let sequence: String? = call.argumentOrNull("sequence");
    let _delayTimeout: Int? = call.argumentOrNull("delayTimeout");
    let delayTimeout: Int = _delayTimeout == nil ? -1 : _delayTimeout!;
    let _enqueueWhileDisconnected: Bool? = call.argumentOrNull("enqueueWhileDisconnected");
    let enqueueWhileDisconnected: Bool = _enqueueWhileDisconnected == nil ? false : _enqueueWhileDisconnected!;
    var listener: ClientMessageDelegate? = nil;
    if (msgId != nil) {
      listener = MyClientMessageListener_(msgId!, self);
    }
    client.sendMessage(message, withSequence: sequence, timeout: delayTimeout, delegate: listener, enqueueWhileDisconnected: enqueueWhileDisconnected);
    result(nil);
  }
  
  func Details_setServerAddress(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let newVal: String? = call.argument("newVal");
    client.connectionDetails.serverAddress = newVal;
    result(nil);
  }
  
  func ConnectionOptions_setForcedTransport(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let newVal: String? = call.argument("newVal");
    client.connectionOptions.forcedTransport = toTransportSelection(newVal);
    result(nil);
  }

  func ConnectionOptions_setRequestedMaxBandwidth(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let newVal: String = call.argument("newVal");
    client.connectionOptions.requestedMaxBandwidth = toMaxBandwidth(newVal);
    result(nil);
  }

  func ConnectionOptions_setReverseHeartbeatInterval(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let newVal: Int = call.argument("newVal");
    client.connectionOptions.reverseHeartbeatInterval = newVal;
    result(nil);
  }
  
  func getSubscription(_ subId: String) throws -> Subscription {
    let sub = _subMap.get(subId);
    if (sub == nil) {
      let errMsg = "Subscription " + subId + " doesn't exist";
      if (channelLogger.isErrorEnabled) {
        channelLogger.error(errMsg);
      }
      throw IllegalStateException(errMsg);
    }
    return sub!;
  }
  
  func Subscription_getCommandPosition(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let res = sub.commandPosition;
    result(res);
  }
  
  func Subscription_getKeyPosition(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let res = sub.keyPosition;
    result(res);
  }
  
  func Subscription_setRequestedMaxFrequency(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let newVal: String? = call.argumentOrNull("newVal");
    let sub = try getSubscription(subId);
    sub.requestedMaxFrequency = toMaxFrequency(newVal);
    result(nil);
  }
  
  func Subscription_isActive(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let res = sub.isActive;
    result(res);
  }
  
  func Subscription_isSubscribed(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let res = sub.isSubscribed;
    result(res);
  }
  
  func Subscription_getValueByItemNameAndFieldName(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: String = call.argument("item");
    let field: String = call.argument("field");
    let res = sub.valueWithItemName(item, fieldName: field);
    result(res);
  }
  
  func Subscription_getValueByItemNameAndFieldPos(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: String = call.argument("item");
    let field: Int = call.argument("field");
    let res = sub.valueWithItemName(item, fieldPos: field);
    result(res);
  }
  
  func Subscription_getValueByItemPosAndFieldName(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: Int = call.argument("item");
    let field: String = call.argument("field");
    let res = sub.valueWithItemPos(item, fieldName: field);
    result(res);
  }
  
  func Subscription_getValueByItemPosAndFieldPos(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: Int = call.argument("item");
    let field: Int = call.argument("field");
    let res = sub.valueWithItemPos(item, fieldPos: field);
    result(res);
  }
  
  func Subscription_getCommandValueByItemNameAndFieldName(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: String = call.argument("item");
    let key: String = call.argument("key");
    let field: String = call.argument("field");
    let res = sub.commandValueWithItemName(item, key: key, fieldName: field);
    result(res);
  }
  
  func Subscription_getCommandValueByItemNameAndFieldPos(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: String = call.argument("item");
    let key: String = call.argument("key");
    let field: Int = call.argument("field");
    let res = sub.commandValueWithItemName(item, key: key, fieldPos: field);
    result(res);
  }
  
  func Subscription_getCommandValueByItemPosAndFieldName(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: Int = call.argument("item");
    let key: String = call.argument("key");
    let field: String = call.argument("field");
    let res = sub.commandValueWithItemPos(item, key: key, fieldName: field);
    result(res);
  }
  
  func Subscription_getCommandValueByItemPosAndFieldPos(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let subId: String = call.argument("subId");
    let sub = try getSubscription(subId);
    let item: Int = call.argument("item");
    let key: String = call.argument("key");
    let field: Int = call.argument("field");
    let res = sub.commandValueWithItemPos(item, key: key, fieldPos: field);
    result(res);
  }

  func invokeMethod(_ method: String, _ arguments: [String:Any?]) {
    if (channelLogger.isDebugEnabled) {
      channelLogger.debug("Invoking " + method + " " + arguments.debugDescription);
    }
    DispatchQueue.main.async {
      self._listenerChannel.invokeMethod(method, arguments: arguments);
    }
  }
  
  func toTransportSelection(_ ft: String?) -> TransportSelection? {
    return ft == nil ? nil : TransportSelection(rawValue: ft!)!
  }
  
  func toMaxBandwidth(_ bwt: String) -> RequestedMaxBandwidth {
    return bwt == "unlimited" ? RequestedMaxBandwidth.unlimited : RequestedMaxBandwidth.limited(Double(bwt)!)
  }
  
  func toMaxFrequency(_ freq: String?) -> Subscription.RequestedMaxFrequency? {
    return switch freq {
    case nil: nil
    case "unlimited": .unlimited
    case "unfiltered": .unfiltered
    default: .limited(Double(freq!)!)
    }
  }
  
  func toBufferSize(_ size: String?) -> Subscription.RequestedBufferSize? {
    return switch size {
    case nil: nil
    case "unlimited": .unlimited
    default: .limited(Int(size!)!)
    }
  }
  
  func toSnapshot(_ snap: String?) -> Subscription.RequestedSnapshot? {
    return switch snap {
    case nil: nil
    case "yes": .yes
    case "no": .no
    default: .length(Int(snap!)!)
    }
  }
}

fileprivate extension FlutterMethodCall {
  func argument<T>(_ name: String) -> T {
    return (arguments as! [String:Any?])[name] as! T
  }
  
  func argumentOrNull<T>(_ name: String) -> T? {
    return (arguments as! [String:Any?])[name] as? T
  }
}

fileprivate extension Dictionary {
  func get(_ key: Key) -> Value? {
    return self[key]
  }
  
  mutating func put(_ key: Key, _ val: Value) {
    self.updateValue(val, forKey: key)
  }
}

fileprivate struct IllegalStateException: LocalizedError {
  let message: String
  var errorDescription: String? { message }

  init(_ msg: String) {
    message = msg
  }
  
  func getMessage() -> String {
    return message
  }
}

fileprivate class MyClientListener_ : ClientDelegate {
  let clientId: String
  weak var client: LightstreamerClient?
  weak var plugin: LightstreamerFlutterPlugin?
  
  init(_ clientId: String, _ client: LightstreamerClient, _ plugin: LightstreamerFlutterPlugin) {
    self.clientId = clientId;
    self.client = client;
    self.plugin = plugin;
  }
  
  func clientDidRemoveDelegate(_ client: LightstreamerClient) {}
  
  func clientDidAddDelegate(_ client: LightstreamerClient) {}
  
  func client(_ client: LightstreamerClient, didReceiveServerError errorCode: Int, withMessage errorMessage: String) {
    var arguments = [String:Any]();
    arguments.put("errorCode", errorCode);
    arguments.put("errorMessage", errorMessage);
    invoke("onServerError", arguments);
  }
  
  func client(_ client: LightstreamerClient, didChangeStatus status: LightstreamerClient.Status) {
    var arguments = [String:Any]();
    arguments.put("status", status.rawValue);
    invoke("onStatusChange", arguments);
  }
  
  func client(_ client: LightstreamerClient, didChangeProperty property: String) {
    var arguments = [String:Any?]();
    arguments.put("property", property);
    switch (property) {
    case "serverInstanceAddress":
      arguments.put("value", client.connectionDetails.serverInstanceAddress);
    case "serverSocketName":
      arguments.put("value", client.connectionDetails.serverSocketName);
    case "clientIp":
      arguments.put("value", client.connectionDetails.clientIp);
    case "sessionId":
      arguments.put("value", client.connectionDetails.sessionId);
    case "realMaxBandwidth":
      let bwt: String? = switch client.connectionOptions.realMaxBandwidth {
      case nil: nil
      case .unlimited: "unlimited"
      case .limited(var val): "\(val)"
      case .unmanaged: "unmanaged"
      }
      arguments.put("value", bwt);
    case "idleTimeout":
      arguments.put("value", client.connectionOptions.idleTimeout);
    case "keepaliveInterval":
      arguments.put("value", client.connectionOptions.keepaliveInterval);
    case "pollingInterval":
      arguments.put("value", client.connectionOptions.pollingInterval);
    default:
      break
    }
    invoke("onPropertyChange", arguments);
  }
  
  func invoke(_ method: String, _ arguments: [String:Any?]) {
    var arguments = arguments
    arguments.put("id", clientId)
    plugin?.invokeMethod("ClientListener." + method, arguments);
  }
}

fileprivate class MyClientMessageListener_ : ClientMessageDelegate {
  let _msgId: String
  weak var _plugin: LightstreamerFlutterPlugin?
  
  init(_ msgId: String, _ plugin: LightstreamerFlutterPlugin) {
    self._msgId = msgId;
    self._plugin = plugin;
  }
  
  func client(_ client: LightstreamerClient, didAbortMessage originalMessage: String, sentOnNetwork: Bool) {
    var arguments = [String:Any?]();
    arguments.put("originalMessage", originalMessage);
    arguments.put("sentOnNetwork", sentOnNetwork);
    invoke("onAbort", arguments);
  }
  
  func client(_ client: LightstreamerClient, didDenyMessage originalMessage: String, withCode code: Int, error: String) {
    var arguments = [String:Any?]();
    arguments.put("originalMessage", originalMessage);
    arguments.put("errorCode", code);
    arguments.put("errorMessage", error);
    invoke("onDeny", arguments);
  }
  
  func client(_ client: LightstreamerClient, didDiscardMessage originalMessage: String) {
    var arguments = [String:Any?]();
    arguments.put("originalMessage", originalMessage);
    invoke("onDiscarded", arguments);
  }
  
  func client(_ client: LightstreamerClient, didFailMessage originalMessage: String) {
    var arguments = [String:Any?]();
    arguments.put("originalMessage", originalMessage);
    invoke("onError", arguments);
  }
  
  func client(_ client: LightstreamerClient, didProcessMessage originalMessage: String, withResponse response: String) {
    var arguments = [String:Any?]();
    arguments.put("originalMessage", originalMessage);
    arguments.put("response", response);
    invoke("onProcessed", arguments);
  }
  
  func invoke(_ method: String, _ arguments: [String:Any?]) {
    var arguments = arguments
    arguments.put("msgId", _msgId)
    _plugin?.invokeMethod("ClientMessageListener." + method, arguments);
  }
}

class MySubscriptionListener : SubscriptionDelegate {
  let _subId: String;
  let _sub: Subscription;
  weak var _plugin: LightstreamerFlutterPlugin?;
  
  init(_ subId: String, _ sub: Subscription, _ plugin: LightstreamerFlutterPlugin) {
    self._subId = subId;
    self._sub = sub;
    self._plugin = plugin;
  }
  
  func subscriptionDidRemoveDelegate(_ subscription: Subscription) {}
  
  func subscriptionDidAddDelegate(_ subscription: Subscription) {}
  
  func subscription(_ subscription: Subscription, didClearSnapshotForItemName itemName: String?, itemPos: UInt) {
    var arguments = [String:Any?]();
    arguments.put("itemName", itemName);
    arguments.put("itemPos", itemPos);
    invoke("onClearSnapshot", arguments);
  }
  
  func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forCommandSecondLevelItemWithKey key: String) {
    var arguments = [String:Any?]();
    arguments.put("lostUpdates", lostUpdates);
    arguments.put("key", key);
    invoke("onCommandSecondLevelItemLostUpdates", arguments);
  }
  
  func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?, forCommandSecondLevelItemWithKey key: String) {
    var arguments = [String:Any?]();
    arguments.put("code", code);
    arguments.put("message", message);
    arguments.put("key", key);
    invoke("onCommandSecondLevelSubscriptionError", arguments);
  }
  
  func subscription(_ subscription: Subscription, didEndSnapshotForItemName itemName: String?, itemPos: UInt) {
    var arguments = [String:Any?]();
    arguments.put("itemName", itemName);
    arguments.put("itemPos", itemPos);
    invoke("onEndOfSnapshot", arguments);
  }
  
  func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forItemName itemName: String?, itemPos: UInt) {
    var arguments = [String:Any?]();
    arguments.put("itemName", itemName);
    arguments.put("itemPos", itemPos);
    arguments.put("lostUpdates", lostUpdates);
    invoke("onItemLostUpdates", arguments);
  }
  
  func subscription(_ subscription: Subscription, didUpdateItem update: any ItemUpdate) {
    // TODO improve performance
    var arguments = [String:Any?]();
    arguments.put("itemName", update.itemName);
    arguments.put("itemPos", update.itemPos);
    arguments.put("isSnapshot", update.isSnapshot);
    if (_sub.fields != nil || _sub.commandSecondLevelFields != nil) {
      // TODO notwithstanding the check above, is it possible that
      // if the subscription doesn't have field names, the methods `changedFields` and
      // `fields` may throw exceptions?
      let changedFields = update.changedFields;
      let fields = update.fields;
      var jsonFields = [String:String?]();
      for fld in fields.keys {
        let json = update.valueAsJSONPatchIfAvailable(withFieldName: fld);
        if (json != nil) {
          jsonFields.put(fld, json);
        }
      }
      arguments.put("changedFields", changedFields);
      arguments.put("fields", fields);
      arguments.put("jsonFields", jsonFields);
    }
    let changedFieldsByPosition = update.changedFieldsByPositions;
    let fieldsByPosition = update.fieldsByPositions;
    var jsonFieldsByPosition = [Int:String?]();
    for pos in fieldsByPosition.keys {
      let json = update.valueAsJSONPatchIfAvailable(withFieldPos: pos);
      if (json != nil) {
        jsonFieldsByPosition.put(pos, json);
      }
    }
    arguments.put("changedFieldsByPosition", changedFieldsByPosition);
    arguments.put("fieldsByPosition", fieldsByPosition);
    arguments.put("jsonFieldsByPosition", jsonFieldsByPosition);
    invoke("onItemUpdate", arguments);
  }
  
  func subscriptionDidSubscribe(_ subscription: Subscription) {
    var arguments = [String:Any?]();
    if (.COMMAND == _sub.mode) {
      arguments.put("commandPosition", _sub.commandPosition);
      arguments.put("keyPosition", _sub.keyPosition);
    }
    invoke("onSubscription", arguments);
  }
  
  func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?) {
    var arguments = [String:Any?]();
    arguments.put("errorCode", code);
    arguments.put("errorMessage", message);
    invoke("onSubscriptionError", arguments);
  }
  
  func subscriptionDidUnsubscribe(_ subscription: Subscription) {
    var arguments = [String:Any?]();
    invoke("onUnsubscription", arguments);
  }
  
  func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {
    var arguments = [String:Any?]();
    var freq: String? = switch frequency {
    case nil: nil
    case .unlimited: "unlimited"
    case .limited(var val): "\(val)"
    }
    arguments.put("frequency", freq);
    invoke("onRealMaxFrequency", arguments);
  }
  
  func invoke(_ method: String, _ arguments: [String:Any?]) {
    var arguments = arguments
    arguments.put("subId", _subId);
    _plugin?.invokeMethod("SubscriptionListener." + method, arguments);
  }
}
