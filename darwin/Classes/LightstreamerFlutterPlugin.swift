import Foundation
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
import Cocoa
#endif
import LightstreamerClient
import os.log

#if os(iOS)
public typealias MyApplication = UIApplication
#elseif os(macOS)
public typealias MyApplication = NSApplication
#endif

/**
 * A plugin manages the communication between the Flutter component (the Flutter app targeting iOS using the Lightstreamer Flutter Client SDK)
 * and this iOS component (the environment running the Lightstreamer iOS Client SDK
 * that performs the operations requested by the Flutter component).
 * See also: https://docs.flutter.dev/platform-integration/platform-channels
 */
public class LightstreamerFlutterPlugin: NSObject, FlutterPlugin {
  
  let channelLogger = LogManager.getLogger("lightstreamer.flutter")
  var _mpnSubIdGenerator = 0
  
  /**
   * Maps a clientId (i.e. the `id` field of a MethodCall object) to a LightstreamerClient.
   * The mapping is created when any LightstreamerClient method is called by the Flutter component.
   * It is removed when the map is cleaned.
   */
  var _clientMap = [String:LightstreamerClient]();
  /**
   * Maps a subId (i.e. the `subId` field of a MethodCall object) to a Subscription.
   * The mapping is created when `LightstreamerClient.subscribe` is called.
   * It is removed when the map is cleaned.
   */
  var _subMap = [String:Subscription]();
  /**
   * Maps an mpnDevId (i.e. the `mpnDevId` field of a MethodCall object) to an MpnDevice.
   * The mapping is created when `LightstreamerClient.registerForMpn` is called.
   * It is removed when the map is cleaned.
   */
  var _mpnDeviceMap = [String:MPNDevice]();
  /**
   * Maps an mpnSubId (i.e. the `mpnSubId` field of a MethodCall object) to an MpnSubscription.
   * The mapping is created either when
   * 1. `LightstreamerClient.subscribeMpn` is called, or
   * 2. a Server MpnSubscription (i.e. an MpnSubscription not created in response to a `LightstreamerClient.subscribeMpn` call)
   *    is returned by `LightstreamerClient.getMpnSubscriptions` or `LightstreamerClient.findMpnSubscription`.
   * The mapping is removed when the map is cleaned.
   */
  var _mpnSubMap = [String:MyMpnSubscription]();
  
  /**
   * The channel through which the procedure calls requested by the Flutter component are received.
   */
  let _methodChannel: FlutterMethodChannel;
  /**
   * The channel through which the events fired by the listeners are communicated to the Flutter component.
   */
  let _listenerChannel: FlutterMethodChannel;
  
  init(_ registrar: FlutterPluginRegistrar) {
#if os(iOS)
    _methodChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/methods", binaryMessenger: registrar.messenger());
    _listenerChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/listeners", binaryMessenger: registrar.messenger());
#elseif os(macOS)
    _methodChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/methods", binaryMessenger: registrar.messenger);
    _listenerChannel = FlutterMethodChannel(name: "com.lightstreamer.flutter/listeners", binaryMessenger: registrar.messenger);
#endif
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LightstreamerFlutterPlugin(registrar)
    registrar.addMethodCallDelegate(instance, channel: instance._methodChannel)
    registrar.addApplicationDelegate(instance)
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
      case "MpnDevice":
        try MpnDevice_handle(methodName, call, result);
      case "MpnSubscription":
        try MpnSubscription_handle(methodName, call, result);
      case "ApnsMpnBuilder":
        try ApnsMpnBuilder_handle(methodName, call, result);
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
  
  func Client_handle(_ method: String, _ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    switch (method) {
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
    case "registerForMpn":
      try Client_registerForMpn(call, result);
    case "subscribeMpn":
      try Client_subscribeMpn(call, result);
    case "unsubscribeMpn":
      try Client_unsubscribeMpn(call, result);
    case "unsubscribeMpnSubscriptions":
      try Client_unsubscribeMpnSubscriptions(call, result);
    case "getMpnSubscriptions":
      try Client_getMpnSubscriptions(call, result);
    case "findMpnSubscription":
      try Client_findMpnSubscription(call, result);
    case "setLoggerProvider":
      Client_setLoggerProvider(call, result);
    case "addCookies":
      try Client_addCookies(call, result);
    case "getCookies":
      try Client_getCookies(call, result);
    case "cleanResources":
      try Client_cleanResources(call, result);
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
  
  func MpnDevice_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented);
    }
  }
  
  func MpnSubscription_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "setTriggerExpression":
      try MpnSubscription_setTriggerExpression(call, result);
    case "setNotificationFormat":
      try MpnSubscription_setNotificationFormat(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented);
    }
  }
  
  func ApnsMpnBuilder_handle(_ method: String, _ call: FlutterMethodCall, _ result: FlutterResult) throws {
    switch (method) {
    case "build":
      try ApnsMpnBuilder_build(call, result);
    default:
      if (channelLogger.isErrorEnabled) {
        channelLogger.error("Unknown method " + call.method);
      }
      result(FlutterMethodNotImplemented);
    }
  }
  
  func getClient(_ call: FlutterMethodCall) throws -> LightstreamerClient {
    let id: String = call.argument("id");
    var ls: LightstreamerClient! = _clientMap.get(id);
    if (ls == nil) {
      ls = LightstreamerClient(serverAddress: nil, adapterSet: nil);
      _clientMap.put(id, ls);
      ls.addDelegate(MyClientListener_(id, ls, self));
    }
    return ls;
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
  
  func Client_addCookies(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let uri: String = call.argument("uri");
    let cookies: [String] = call.argument("cookies");
    let uri_: URL! = URL(string: uri)
    if (uri_ == nil) {
      throw IllegalStateException("Invalid URL `\(uri)` in LightstreamerClient.addCookies")
    }
    let cookies_ = cookies.flatMap({ c in HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie":c], for: uri_)})
    LightstreamerClient.addCookies(cookies_, forURL: uri_);
    result(nil);
  }
  
  func Client_getCookies(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let uri: String = call.argument("uri");
    let uri_: URL! = URL(string: uri)
    if (uri_ == nil) {
      throw IllegalStateException("Invalid URL `\(uri)` in LightstreamerClient.getCookies")
    }
    let res = LightstreamerClient.getCookiesForURL(uri_)?.map({c in cookieToString(c)}) ?? []
    result(res)
  }
  
  /**
   * Formats a cookie according to the Set-Cookie header specification.
   *
   * https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
   */
  func cookieToString(_ c: HTTPCookie) -> String {
    var result = ""
    result.append(c.name);
    result.append("=");
    result.append(c.value);
    if (!c.domain.isEmpty)
    {
      result.append("; domain=");
      result.append(c.domain);
    }
    if (!c.path.isEmpty)
    {
      result.append("; path=");
      result.append(c.path);
    }
    if let expires = c.expiresDate
    {
      result.append("; Expires=" + formatCookieDate(expires));
    }
    if #available(iOS 13.0, macOS 10.15, *) {
      switch (c.sameSitePolicy) {
      case .sameSiteLax:
        result.append("; SameSite=Lax");
      case .sameSiteStrict:
        result.append("; SameSite=Strict");
      default:
        break
      }
    }
    if (c.isSecure)
    {
      result.append("; secure");
    }
    if (c.isHTTPOnly)
    {
      result.append("; HttpOnly");
    }
    return result;
  }
  
  /**
   * Formats a date according to the HTTP-date standard.
   *
   * See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Date
   */
  func formatCookieDate(_ d: Date) -> String {
    // Date: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
    // <day-name> One of "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", or "Sun" (case-sensitive).
    // <month> One of "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" (case sensitive).
    let calendar = Calendar(identifier: .gregorian)
    let dayName = dayNames[calendar.component(.weekday, from: d)]
    let day = calendar.component(.day, from: d)
    let month = monthNames[calendar.component(.month, from: d)]
    let year = calendar.component(.month, from: d)
    let hour = calendar.component(.hour, from: d)
    let minute = calendar.component(.minute, from: d)
    let second = calendar.component(.second, from: d)
    return "\(dayName), \(day) \(month) \(year) \(hour):\(minute):\(second) GMT"
  }
  
  let monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  
  func Client_cleanResources(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let clientIds: [String] = call.argument("clientIds")
    let subIds: [String] = call.argument("subIds")
    let mpnDevIds: [String] = call.argument("mpnDevIds")
    let mpnSubIds: [String] = call.argument("mpnSubIds")
    var removedClientIds = 0
    for id in clientIds {
      let res = _clientMap.removeValue(forKey: id)
      removedClientIds += res == nil ? 0 : 1
    }
    var removedSubIds = 0
    for id in subIds {
      let res = _subMap.removeValue(forKey: id)
      removedSubIds += res == nil ? 0 : 1
    }
    var removedDevIds = 0
    for id in mpnDevIds {
      let res = _mpnDeviceMap.removeValue(forKey: id)
      removedDevIds += res == nil ? 0 : 1
    }
    var removedMpnSubIds = 0
    for id in mpnSubIds {
      let res = _mpnSubMap.removeValue(forKey: id)
      removedMpnSubIds += res == nil ? 0 : 1
    }
    if (channelLogger.isDebugEnabled) {
      channelLogger.debug("Cleaned clients: \(removedClientIds) subscriptions: \(removedSubIds) devices: \(removedDevIds) mpn subscriptions: \(removedMpnSubIds)")
    }
    result(nil)
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
  
  func Client_registerForMpn(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) throws {
    let client = try getClient(call);
    let mpnDevId: String = call.argument("mpnDevId");
    let device_ = _mpnDeviceMap.get(mpnDevId);
    if (device_ != nil) {
      client.register(forMPN: device_!);
      result(nil);
      return;
    }
    // mpnDevId is unknown: get a device token and create a new device
    let onTokenError = { [weak self] errMsg in
      guard let self = self else {
        return
      }
      if (self.channelLogger.isErrorEnabled) {
        self.channelLogger.error(errMsg);
      }
      result(FlutterError(code: "Lightstreamer Internal Error", message: errMsg, details: nil))
    }
    let onTokenSuccess = { [weak self] token in
      guard let self = self else {
        return
      }
      // TODO synchronize access to `_mpnDeviceMap`?
      if (_mpnDeviceMap.keys.contains(mpnDevId)) {
        let errMsg = "MpnDevice " + mpnDevId + " already exists";
        if (channelLogger.isErrorEnabled) {
          channelLogger.error(errMsg);
        }
        result(FlutterError(code: "Lightstreamer Internal Error", message: errMsg, details: nil));
        return;
      }
      let device = MPNDevice(deviceToken: token);
      device.addDelegate(MyMpnDeviceListener(mpnDevId, device, self));
      _mpnDeviceMap.put(mpnDevId, device);
      client.register(forMPN: device);
      
      result(nil);
    }
    if (channelLogger.isDebugEnabled) {
      channelLogger.debug("Obtaining MPN Device Token")
    }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      self.tokenListeners.append((onTokenSuccess, onTokenError))
      MyApplication.shared.registerForRemoteNotifications()
    }
  }
  
  // NB the array should be accessed inside the main dispatch queue
  var tokenListeners = [((String)->(), (String)->())]()
  
  public func application(_ application: MyApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    if (self.channelLogger.isDebugEnabled) {
      self.channelLogger.debug("MPN Device Token obtained")
    }
    let token = deviceToken.map { data in String(format: "%02x", data) }.joined()
    // fire the success listeners and then remove them
    for (onTokenSuccess, _) in tokenListeners {
      onTokenSuccess(token)
    }
    tokenListeners.removeAll()
  }

  public func application(_ application: MyApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    let errMsg = "MPN Device Token not available: \(error) (user info: \((error as NSError).userInfo))"
    if (self.channelLogger.isErrorEnabled) {
      self.channelLogger.error(errMsg)
    }
    // fire the error listeners and then remove them
    for (_, onTokenError) in tokenListeners {
      onTokenError(errMsg)
    }
    tokenListeners.removeAll()
  }
  
  func Client_subscribeMpn(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let options: [String:Any?] = call.argument("subscription");
    let mpnSubId = options.get("id") as! String;
    let mode = options.get("mode") as! String;
    let items = options.get("items") as? [String];
    let fields = options.get("fields") as? [String];
    let group = options.get("group") as? String;
    let schema = options.get("schema") as? String;
    let dataAdapter = options.get("dataAdapter") as? String;
    let bufferSize = options.get("bufferSize") as? String;
    let requestedMaxFrequency = options.get("requestedMaxFrequency") as? String;
    let trigger = options.get("trigger") as? String;
    let format = options.get("notificationFormat") as? String;
    let coalescing: Bool = call.argument("coalescing");
    var mySub: MyMpnSubscription! = _mpnSubMap.get(mpnSubId);
    if (mySub == nil) {
      let sub = MPNSubscription(subscriptionMode: MPNSubscription.Mode(rawValue: mode)!);
      sub.addDelegate(MyMpnSubscriptionListener(mpnSubId, sub, self));
      mySub = MyMpnSubscription(client, mpnSubId, sub);
      _mpnSubMap.put(mpnSubId, mySub);
    } else if (client !== mySub!._client) {
      // NB since a MyMpnSubscription keeps a reference to the client that subscribes to
      // the underlying MpnSubscription, the reference must be updated when the same MpnSubscription
      // is subscribed to by another client
      mySub = MyMpnSubscription(client, mpnSubId, mySub._sub);
      _mpnSubMap.put(mpnSubId, mySub);
    }
    let sub = mySub._sub;
    if (sub.isActive) {
      throw IllegalStateException("Cannot subscribe to an active MpnSubscription");
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
      sub.requestedBufferSize = toMpnBufferSize(bufferSize);
    }
    if (requestedMaxFrequency != nil) {
      sub.requestedMaxFrequency = toMpnMaxFrequency(requestedMaxFrequency);
    }
    if (trigger != nil) {
      sub.triggerExpression = trigger;
    }
    if (format != nil) {
      sub.notificationFormat = format;
    }
    client.subscribeMPN(sub, coalescing: coalescing);
    result(nil);
  }
  
  func Client_unsubscribeMpn(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let mpnSubId: String = call.argument("mpnSubId");
    let sub = try getMpnSubscription(mpnSubId);
    client.unsubscribeMPN(sub);
    result(nil);
  }
  
  func Client_unsubscribeMpnSubscriptions(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let filter: String? = call.argumentOrNull("filter");
    let filter_: LightstreamerClient.MPNSubscriptionStatus = switch filter {
    case nil, "ALL": .ALL
    case "SUBSCRIBED": .SUBSCRIBED
    case "TRIGGERED": .TRIGGERED
    default:
      throw IllegalStateException("Unknown filter `\(filter ?? "nil")` in unsubscribeMpnSubscriptions")
    }
    client.unsubscribeMultipleMPN(filter_);
    result(nil);
  }
  
  func nextServerMpnSubId() -> String {
    // IMPLEMENTATION NOTE
    // since mpnSubIds for user subscriptions are generated by the Flutter component
    // while mpnSubIds for server subscriptions are generated by this iOS component,
    // a simple way to ensure that server and user mpnSubIds are unique is to use different prefixes,
    // i.e. "mpnsub" for user subscriptions and "mpnsub-server" for server subscriptions
    let id = _mpnSubIdGenerator
    _mpnSubIdGenerator += 1
    return "mpnsub-server\(id)";
  }
  
  func Client_getMpnSubscriptions(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let filter: String? = call.argumentOrNull("filter");
    let filter_: LightstreamerClient.MPNSubscriptionStatus = switch filter {
    case nil, "ALL": .ALL
    case "SUBSCRIBED": .SUBSCRIBED
    case "TRIGGERED": .TRIGGERED
    default:
      throw IllegalStateException("Unknown filter `\(filter ?? "nil")` in getMpnSubscriptions")
    }
    let subs = client.filterMPNSubscriptions(filter_);
    //
    var knownSubs = [String]();
    var unknownSubs = [[String:Any?]]();
    for sub in subs {
      let subscriptionId = sub.subscriptionId; // can be null
      // 1. search a subscription known to the Flutter component (i.e. in `_mpnSubMap`) and owned by `client` having the same subscriptionId
      if (subscriptionId != nil) { // defensive check, even if `subscriptionId` should not be null
        var mpnSubId: String? = nil;
        for (key, value) in _mpnSubMap {
          let mySub: MyMpnSubscription = value;
          if (mySub._client === client && subscriptionId == mySub._sub.subscriptionId) {
            mpnSubId = key;
            break;
          }
        }
        if (mpnSubId != nil) {
          // 2.A. there is such a subscription: it means that `sub` is known to the Flutter component
          knownSubs.append(mpnSubId!);
        } else {
          // 2.B. there isn't such a subscription: it means that `sub` is unknown to the Flutter component
          // (i.e. it is a new server subscription)
          // add it to `_mpnSubMap` and add a listener so the Flutter component can receive subscription events
          mpnSubId = nextServerMpnSubId();
          sub.addDelegate(MyMpnSubscriptionListener(mpnSubId!, sub, self));
          let mySub = MyMpnSubscription(client, mpnSubId!, sub);
          _mpnSubMap.put(mpnSubId!, mySub);
          // serialize `sub` in order to send it to the Flutter component
          let dto = mySub.toMap();
          unknownSubs.append(dto);
        }
      } else {
        if (channelLogger.isWarnEnabled) {
          channelLogger.warn("MpnSubscription.subscriptionId should not be null, but it is");
        }
      }
    }
    var res = [String:Any]();
    res.put("result", knownSubs);
    res.put("extra", unknownSubs);
    result(res);
  }
  
  func Client_findMpnSubscription(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let client = try getClient(call);
    let subscriptionId: String = call.argument("subscriptionId");
    let sub: MPNSubscription! = client.findMPNSubscription(subscriptionId);
    //
    var res = [String:Any?]();
    if (sub != nil) {
      // 1. search a subscription known to the Flutter component (i.e. in `_mpnSubMap`) and owned by `client` having the same subscriptionId
      var mpnSubId: String! = nil;
      for (key, value) in _mpnSubMap {
        let mySub = value;
        if (mySub._client === client && subscriptionId == mySub._sub.subscriptionId) {
          mpnSubId = key;
          break;
        }
      }
      if (mpnSubId != nil) {
        // 2.A. there is such a subscription: it means that `sub` is known to the Flutter component
        res.put("result", mpnSubId);
      } else {
        // 2.B. there isn't such a subscription: it means that `sub` is unknown to the Flutter component
        // (i.e. it is a new server subscription)
        // add it to `_mpnSubMap` and add a listener so the Flutter component can receive subscription events
        mpnSubId = nextServerMpnSubId();
        sub.addDelegate(MyMpnSubscriptionListener(mpnSubId, sub, self));
        let mySub = MyMpnSubscription(client, mpnSubId, sub);
        _mpnSubMap.put(mpnSubId, mySub);
        // serialize `sub` in order to send it to the Flutter component
        let dto = mySub.toMap();
        res.put("extra", dto);
      }
    } // else if sub == null, return an empty map
    result(res);
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
  
  func getMpnSubscription(_ mpnSubId: String) throws -> MPNSubscription {
    let mySub = _mpnSubMap.get(mpnSubId);
    if (mySub == nil) {
      let errMsg = "MpnSubscription " + mpnSubId + " doesn't exist";
      if (channelLogger.isErrorEnabled) {
        channelLogger.error(errMsg);
      }
      throw IllegalStateException(errMsg);
    }
    return mySub!._sub;
  }
  
  func MpnSubscription_setTriggerExpression(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let mpnSubId: String = call.argument("mpnSubId");
    let sub = try getMpnSubscription(mpnSubId);
    sub.triggerExpression = call.argumentOrNull("trigger");
    result(nil);
  }
  
  func MpnSubscription_setNotificationFormat(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let mpnSubId: String = call.argument("mpnSubId");
    let sub = try getMpnSubscription(mpnSubId);
    sub.notificationFormat = call.argumentOrNull("notificationFormat");
    result(nil);
  }
  
  func ApnsMpnBuilder_build(_ call: FlutterMethodCall, _ result: FlutterResult) throws {
    let alert: String? = call.argumentOrNull("alert")
    let badge: String? = call.argumentOrNull("badge")
    let body: String? = call.argumentOrNull("body")
    let bodyLocArguments: [String]? = call.argumentOrNull("bodyLocArguments")
    let bodyLocKey: String? = call.argumentOrNull("bodyLocKey")
    let category: String? = call.argumentOrNull("category")
    let contentAvailable: String? = call.argumentOrNull("contentAvailable")
    let mutableContent: String? = call.argumentOrNull("mutableContent")
    let customData: [String:Any]? = call.argumentOrNull("customData")
    let launchImage: String? = call.argumentOrNull("launchImage")
    let locActionKey: String? = call.argumentOrNull("locActionKey")
    let sound: String? = call.argumentOrNull("sound")
    let threadId: String? = call.argumentOrNull("threadId")
    let title: String? = call.argumentOrNull("title")
    let subtitle: String? = call.argumentOrNull("subtitle")
    let titleLocArguments: [String]? = call.argumentOrNull("titleLocArguments")
    let titleLocKey: String? = call.argumentOrNull("titleLocKey")
    let notificationFormat: String? = call.argumentOrNull("notificationFormat")
    let builder: MPNBuilder = notificationFormat == nil ? MPNBuilder() : MPNBuilder(notificationFormat: notificationFormat!)!;
    builder.alert(alert)
    builder.badge(with: badge)
    builder.body(body)
    builder.bodyLocArguments(bodyLocArguments)
    builder.bodyLocKey(bodyLocKey)
    builder.category(category)
    builder.contentAvailable(with: contentAvailable)
    builder.mutableContent(with: mutableContent)
    builder.customData(customData)
    builder.launchImage(launchImage)
    builder.locActionKey(locActionKey)
    builder.sound(sound)
    builder.threadId(threadId)
    builder.title(title)
    builder.subtitle(subtitle)
    builder.titleLocArguments(titleLocArguments)
    builder.titleLocKey(titleLocKey)
    let res = builder.build()
    result(res)
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
  
  func toMpnMaxFrequency(_ freq: String?) -> MPNSubscription.RequestedMaxFrequency? {
    return switch freq {
    case nil: nil
    case "unlimited": .unlimited
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
  
  func toMpnBufferSize(_ size: String?) -> MPNSubscription.RequestedBufferSize? {
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
      case .limited(let val): "\(val)"
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
    var arguments = [String:Any?]();
    arguments.put("itemName", update.itemName);
    arguments.put("itemPos", update.itemPos);
    arguments.put("isSnapshot", update.isSnapshot);
    if (_sub.fields != nil || _sub.commandSecondLevelFields != nil) {
      // TODO could the methods `changedFields` and `fields` throw exceptions if the subscription lacks field names?
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
    let arguments = [String:Any?]();
    invoke("onUnsubscription", arguments);
  }
  
  func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {
    var arguments = [String:Any?]();
    let freq: String? = switch frequency {
    case nil: nil
    case .unlimited: "unlimited"
    case .limited(let val): "\(val)"
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

class MyMpnSubscription {
  // WARNING when a client different from `_client` subscribes to `_sub`,
  // the client reference must be updated (see the implementation of `LightstreamerClient.subscribeMpn`)
  let _client: LightstreamerClient;
  let _mpnSubId: String;
  let _sub: MPNSubscription;

  init(_ client: LightstreamerClient, _ mpnSubId: String, _ sub: MPNSubscription) {
    _client = client;
    _mpnSubId = mpnSubId;
    _sub = sub;
  }

  func toMap() -> [String:Any?] {
    var dto = [String:Any?]();
    dto.put("id", _mpnSubId);
    dto.put("mode", _sub.mode.rawValue);
    dto.put("items", _sub.items);
    dto.put("fields", _sub.fields);
    dto.put("group", _sub.itemGroup);
    dto.put("schema", _sub.fieldSchema);
    dto.put("dataAdapter", _sub.dataAdapter);
    let bs_: String? = switch _sub.requestedBufferSize {
    case nil: nil
    case .unlimited: "unlimited"
    case .limited(let bs): "\(bs)"
    }
    dto.put("bufferSize", bs_);
    let mf_: String? = switch _sub.requestedMaxFrequency {
    case nil: nil
    case .unlimited: "unlimited"
    case .limited(let mf): "\(mf)"
    }
    dto.put("requestedMaxFrequency", mf_);
    dto.put("notificationFormat", _sub.notificationFormat);
    dto.put("trigger", _sub.triggerExpression);
    dto.put("actualNotificationFormat", _sub.actualNotificationFormat);
    dto.put("actualTrigger", _sub.actualTriggerExpression);
    dto.put("statusTs", _sub.statusTimestamp);
    dto.put("status", _sub.status.rawValue);
    dto.put("subscriptionId", _sub.subscriptionId);
    return dto;
  }
}

class MyMpnDeviceListener : MPNDeviceDelegate {
  let _mpnDevId: String;
  let _device: MPNDevice;
  weak var _plugin: LightstreamerFlutterPlugin?;

  init(_ mpnDevId: String, _ device: MPNDevice, _ plugin: LightstreamerFlutterPlugin) {
    self._mpnDevId = mpnDevId;
    self._device = device;
    self._plugin = plugin;
  }
  
  func mpnDeviceDidAddDelegate(_ device: MPNDevice) {}
  
  func mpnDeviceDidRemoveDelegate(_ device: MPNDevice) {}
  
  func mpnDeviceDidRegister(_ device: MPNDevice) {
    var arguments = [String:Any?]();
    arguments.put("applicationId", _device.applicationId);
    arguments.put("deviceId", _device.deviceId);
    arguments.put("deviceToken", _device.deviceToken);
    arguments.put("platform", _device.platform);
    arguments.put("previousDeviceToken", _device.previousDeviceToken);
    invoke("onRegistered", arguments);
  }
  
  func mpnDeviceDidSuspend(_ device: MPNDevice) {
    invoke("onSuspended");
  }
  
  func mpnDeviceDidResume(_ device: MPNDevice) {
    invoke("onResumed");
  }
  
  func mpnDevice(_ device: MPNDevice, didChangeStatus status: MPNDevice.Status, timestamp: Int64) {
    var arguments = [String:Any?]();
    arguments.put("status", status.rawValue);
    arguments.put("timestamp", timestamp);
    invoke("onStatusChanged", arguments);
  }
  
  func mpnDevice(_ device: MPNDevice, didFailRegistrationWithErrorCode code: Int, message: String?) {
    var arguments = [String:Any?]();
    arguments.put("errorCode", code);
    arguments.put("errorMessage", message);
    invoke("onRegistrationFailed", arguments);
  }
  
  func mpnDeviceDidUpdateSubscriptions(_ device: MPNDevice) {
    invoke("onSubscriptionsUpdated");
  }
  
  func mpnDeviceDidResetBadge(_ device: MPNDevice) {
    // TODO to be implemented
  }
  
  func mpnDevice(_ device: MPNDevice, didFailBadgeResetWithErrorCode code: Int, message: String?) {
    // TODO to be implemented
  }
  
  func invoke(_ method: String, _ arguments: [String:Any?]) {
    var arguments = arguments;
    arguments.put("mpnDevId", _mpnDevId);
    _plugin?.invokeMethod("MpnDeviceListener." + method, arguments);
  }
  
  func invoke(_ method: String) {
    invoke(method, [String:Any?]());
  }
}

class MyMpnSubscriptionListener : MPNSubscriptionDelegate {
  let _mpnSubId: String;
  let _sub: MPNSubscription;
  weak var _plugin: LightstreamerFlutterPlugin?;
  
  init(_ mpnSubId: String, _ sub: MPNSubscription, _ plugin: LightstreamerFlutterPlugin) {
    self._mpnSubId = mpnSubId;
    self._sub = sub;
    self._plugin = plugin;
  }
  
  func mpnSubscriptionDidAddDelegate(_ subscription: MPNSubscription) {}
  
  func mpnSubscriptionDidRemoveDelegate(_ subscription: MPNSubscription) {}
  
  func mpnSubscriptionDidSubscribe(_ subscription: MPNSubscription) {
    let arguments = [String:Any?]()
    invoke("onSubscription", arguments);
  }
  
  func mpnSubscriptionDidUnsubscribe(_ subscription: MPNSubscription) {
    let arguments = [String:Any?]()
    invoke("onUnsubscription", arguments);
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailSubscriptionWithErrorCode code: Int, message: String?) {
    var arguments = [String:Any?]()
    arguments.put("errorCode", code);
    arguments.put("errorMessage", message);
    invoke("onSubscriptionError", arguments);
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailUnsubscriptionWithErrorCode code: Int, message: String?) {
    var arguments = [String:Any?]()
    arguments.put("errorCode", code);
    arguments.put("errorMessage", message);
    invoke("onUnsubscriptionError", arguments);
  }
  
  func mpnSubscriptionDidTrigger(_ subscription: MPNSubscription) {
    let arguments = [String:Any?]()
    invoke("onTriggered", arguments);
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didChangeStatus status: MPNSubscription.Status, timestamp: Int64) {
    var arguments = [String:Any?]()
    arguments.put("status", status.rawValue);
    arguments.put("timestamp", timestamp);
    arguments.put("subscriptionId", _sub.subscriptionId);
    invoke("onStatusChanged", arguments);
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didChangeProperty propertyName: String) {
    var arguments = [String:Any?]()
    arguments.put("property", propertyName);
    switch (propertyName) {
    case "status_timestamp":
      arguments.put("value", _sub.statusTimestamp);
    case "mode":
      arguments.put("value", _sub.mode.rawValue);
    case "adapter":
      arguments.put("value", _sub.dataAdapter);
    case "group":
      arguments.put("value", _sub.itemGroup);
    case "schema":
      arguments.put("value", _sub.fieldSchema);
    case "notification_format":
      arguments.put("value", _sub.actualNotificationFormat);
    case "trigger":
      arguments.put("value", _sub.actualTriggerExpression);
    case "requested_buffer_size":
      let bs: String? = switch _sub.requestedBufferSize {
      case nil: nil
      case .unlimited: "unlimited"
      case .limited(let val): "\(val)"
      }
      arguments.put("value", bs);
    case "requested_max_frequency":
      let fr: String? = switch _sub.requestedMaxFrequency {
      case nil: nil
      case .unlimited: "unlimited"
      case .limited(let val): "\(val)"
      }
      arguments.put("value", fr);
    default:
      break
    }
    invoke("onPropertyChanged", arguments);
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailModificationWithErrorCode code: Int, message: String?, property: String) {
    var arguments = [String:Any?]()
    arguments.put("errorCode", code);
    arguments.put("errorMessage", message);
    arguments.put("propertyName", property);
    invoke("onModificationError", arguments);
  }
  
  func invoke(_ method: String, _ arguments: [String:Any?]) {
    var arguments = arguments;
    arguments.put("mpnSubId", _mpnSubId);
    _plugin?.invokeMethod("MpnSubscriptionListener." + method, arguments);
  }
}
