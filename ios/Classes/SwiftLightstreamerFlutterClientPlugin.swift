import Flutter
import UIKit
import os.log
import LightstreamerClient

public class SwiftLightstreamerFlutterClientPlugin: NSObject, FlutterPlugin {
  
  let clientstatus_channel: FlutterBasicMessageChannel
  let messagestatus_channel: FlutterBasicMessageChannel
  let subscribedata_channel: FlutterBasicMessageChannel
  
  var activeSubs: [String:Subscription] = [:]
  var activeMpnSubs: [String:MPNSubscription] = [:]
  
  var prgs_sub = 0
  
  let ls = LightstreamerClient(serverAddress: nil, adapterSet: nil)
  
  var clientListener: MyClientListener!
  var msgListener: MyClientMessageListener!
  var activeSubListeners: [String:MySubListener] = [:]
  var activeMpnListeners: [String:MyMpnSubListener] = [:]

  let category = OSLog(subsystem: "com.lightstreamer", category: "lightstreamer.flutter")
  
  let lsBridge = LightstreamerBridge()
  
  init(_ registrar: FlutterPluginRegistrar) {
    clientstatus_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.status", binaryMessenger: registrar.messenger(), codec: FlutterStringCodec.sharedInstance())
    messagestatus_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.messages", binaryMessenger: registrar.messenger(), codec: FlutterStringCodec.sharedInstance())
    subscribedata_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.realtime", binaryMessenger: registrar.messenger(), codec: FlutterStringCodec.sharedInstance())
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.lightstreamer.lightstreamer_flutter_client.method", binaryMessenger: registrar.messenger())
    let instance = SwiftLightstreamerFlutterClientPlugin(registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    switch method {
    case "connect":
      if lsBridge.hasId(call) {
        lsBridge.connect(call, result, clientstatus_channel)
      } else {
        connect(call, result)
      }
    case "disconnect":
      if lsBridge.hasId(call) {
        lsBridge.disconnect(call, result)
      } else {
        disconnect(call, result)
      }
    case "sendMessage":
      sendMessage(call, result)
    case "sendMessageExt":
      if lsBridge.hasId(call) {
        lsBridge.sendMessageExt(call, result, messagestatus_channel)
      } else {
        sendMessageExt(call, result)
      }
    case "subscribe":
      if lsBridge.hasId(call) {
        lsBridge.subscribe(call, result, subscribedata_channel)
      } else {
        subscribe(call, result)
      }
    case "unsubscribe":
      if lsBridge.hasId(call) {
        lsBridge.unsubscribe(call, result)
      } else {
        unsubscribe(call, result)
      }
    case "mpnSubscribe":
      if lsBridge.hasId(call) {
        lsBridge.mpnSubscribe(call, result, subscribedata_channel)
      } else {
        mpnSubscribe(call, result)
      }
    case "mpnUnsubscribe":
      if lsBridge.hasId(call) {
        lsBridge.mpnUnsubscribe(call, result)
      } else {
        mpnUnsubscribe(call, result)
      }
    case "getStatus":
      if lsBridge.hasId(call) {
        result(lsBridge.getStatus(call))
      } else {
        result(getStatus())
      }
    case "enableLog":
      enableLog()
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func enableLog() {
    LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(level: ConsoleLogLevel.debug))
  }
  
  func mpnUnsubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    
    if let sub_id = arguments["sub_id"] {
      
      let sub = activeMpnSubs.removeValue(forKey: sub_id)
      if sub != nil {
        ls.unsubscribeMPN(sub!)
        activeMpnListeners.removeValue(forKey: sub_id)
      }
      
      result("Ok")
    } else {
      result(FlutterError(code: "4", message: "No Sub Id specified", details: nil))
    }
  }
  
  func mpnSubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:Any]
    
    if let param = arguments["mode"], let value = param as? String {
      let mode = MPNSubscription.Mode(rawValue: value)!
      
      if let param = arguments["itemList"], let value = param as? [String] {
        let itemArr = value
      
        if let param = arguments["fieldList"], let value = param as? [String] {
          let sub_id = "Ok\(prgs_sub)"
          prgs_sub += 1
          
          let fieldArr = value
          
          let sub = MPNSubscription(subscriptionMode: mode, items: itemArr, fields: fieldArr)
          
          if let param = arguments["dataAdapter"], let value = param as? String {
            sub.dataAdapter = value
          }
          
          if let param = arguments["requestedBufferSize"], let value = param as? String {
            if value == "unlimited" {
              sub.requestedBufferSize = .unlimited
            } else if let size = Int(value) {
              sub.requestedBufferSize = .limited(size)
            }
          }
          
          if let param = arguments["requestedMaxFrequency"], let value = param as? String {
            if value == "unlimited" {
              sub.requestedMaxFrequency = .unlimited
            } else if let freq = Double(value) {
              sub.requestedMaxFrequency = .limited(freq)
            }
          }
          
          if let param = arguments["notificationFormat"], let value = param as? String {
            sub.notificationFormat = value
          }
          
          if let param = arguments["triggerExpression"], let value = param as? String {
            sub.triggerExpression = value
          }
          
          let mpnListener = MyMpnSubListener(subscribedata_channel, sub_id)
          sub.addDelegate(mpnListener)

          ls.subscribeMPN(sub, coalescing: true)
          
          activeMpnSubs[sub_id] = sub
          activeMpnListeners[sub_id] = mpnListener
          
          result(sub_id)
          
        } else {
          result(FlutterError(code: "1", message: "No Fields List specified", details: nil))
        }
      } else {
        result(FlutterError(code: "2", message: "No Items List specified", details: nil))
      }
    } else {
      result(FlutterError(code: "3", message: "No subscription mode specified", details: nil))
    }
  }
  
  func unsubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    
    if let sub_id = arguments["sub_id"] {
      
      let sub = activeSubs.removeValue(forKey: sub_id)
      if sub != nil {
        ls.unsubscribe(sub!)
        activeSubListeners.removeValue(forKey: sub_id)
      }
      
      result("Ok")
    } else {
      result(FlutterError(code: "5", message: "No Sub Id specified", details: nil))
    }
  }
  
  func subscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:Any]
    
    let mode = Subscription.Mode(rawValue: arguments["mode"] as! String)!
    let sub = Subscription(subscriptionMode: mode)
    
    if let itemList = arguments["itemList"] as? [String] {
      sub.items = itemList
    }
    if let itemGroup = arguments["itemGroup"] as? String {
      sub.itemGroup = itemGroup
    }
    if let fieldList = arguments["fieldList"] as? [String] {
      sub.fields = fieldList
    }
    if let fieldSchema = arguments["fieldSchema"] as? String {
      sub.fieldSchema = fieldSchema
    }
    
    let sub_id = "Ok\(prgs_sub)"
    prgs_sub += 1
    
    if let param = arguments["dataAdapter"], let value = param as? String {
      sub.dataAdapter = value
    }
    
    if let param = arguments["requestedSnapshot"], let value = param as? String {
      if value == "yes" {
        sub.requestedSnapshot = .yes
      } else if value == "no" {
        sub.requestedSnapshot = .no
      } else if let len = Int(value) {
        sub.requestedSnapshot = .length(len)
      }
    }
    
    if let param = arguments["requestedBufferSize"], let value = param as? String {
      if value == "unlimited" {
        sub.requestedBufferSize = .unlimited
      } else if let size = Int(value) {
        sub.requestedBufferSize = .limited(size)
      }
    }
    
    if let param = arguments["requestedMaxFrequency"], let value = param as? String {
      if value == "unlimited" {
        sub.requestedMaxFrequency = .unlimited
      } else if value == "unfiltered" {
        sub.requestedMaxFrequency = .unfiltered
      } else if let freq = Double(value) {
        sub.requestedMaxFrequency = .limited(freq)
      }
    }
    
    if let param = arguments["commandSecondLevelDataAdapter"], let value = param as? String {
      sub.commandSecondLevelDataAdapter = value
    }
    
    if let param = arguments["commandSecondLevelFields"], let value = param as? String {
      sub.commandSecondLevelFields = value.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }
    
    let subListener = MySubListener(subscribedata_channel, sub_id, sub)
    sub.addDelegate(subListener)
    
    ls.subscribe(sub)
    
    activeSubs[sub_id] = sub
    activeSubListeners[sub_id] = subListener
    
    result(sub_id)
  }
  
  func sendMessageExt(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:Any]
    if let msg = arguments["message"] as? String {
      var timeout = -1
      var seq: String? = nil
      var enq = false
      var addListnr = false
      
      if let param = arguments["sequence"] {
        if let sequence = param as? String {
          seq = sequence
        } else {
          seq = nil
        }
      }
      
      if let param = arguments["delayTimeout"] as? Millis {
        timeout = param
      }
      
      if let param = arguments["enqueueWhileDisconnected"] as? Bool {
        enq = param
      }
      
      if let param = arguments["listener"] as? Bool  {
        addListnr = param
      }
      
      if addListnr {
        msgListener = MyClientMessageListener(messagestatus_channel, "-1", lsBridge)
        ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: msgListener, enqueueWhileDisconnected: enq)
      } else {
        ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: nil, enqueueWhileDisconnected: enq)
      }
      
      result("Ok")
      
    } else {
      result(FlutterError(code: "9", message: "No message", details: nil))
    }
  }
  
  func sendMessage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    if let msg = arguments["message"] {
      ls.sendMessage(msg)
      
      result("Ok")
      
    } else {
      result(FlutterError(code: "10", message: "No message", details: nil))
    }
  }
  
  func disconnect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    ls.disconnect()
    clientListener = nil
      
    result(getStatus())
  }
  
  func connect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    
    if let param = arguments["serverAddress"] {
      ls.connectionDetails.serverAddress = param
    } else {
      result(FlutterError(code: "11", message: "No server address was configured", details: nil))
      return // early exit
    }
    
    if let param = arguments["adapterSet"] {
      ls.connectionDetails.adapterSet = param
    } else {
      result(FlutterError(code: "12", message: "No adapter set id was configured", details: nil))
      return // early exit
    }
    
    if !ls.delegates.isEmpty {
      ls.removeDelegate(ls.delegates[0])
    }
    
    if let param = arguments["user"] {
      ls.connectionDetails.user = param
    }
    
    if let param = arguments["password"] {
      ls.connectionDetails.setPassword(param)
    }
    
    if let param = arguments["forcedTransport"] {
      ls.connectionOptions.forcedTransport = TransportSelection(rawValue: param)!
    }
    
    if let param = arguments["firstRetryMaxDelay"], let value = Millis(param) {
      ls.connectionOptions.firstRetryMaxDelay = value
    }
    
    if let param = arguments["retryDelay"], let value = Millis(param) {
      ls.connectionOptions.retryDelay = value
    }
    
    if let param = arguments["idleTimeout"], let value = Millis(param) {
      ls.connectionOptions.idleTimeout = value
    }
    
    if let param = arguments["reconnectTimeout"], let value = Millis(param) {
      ls.connectionOptions.reconnectTimeout = value
    }
    
    if let param = arguments["stalledTimeout"], let value = Millis(param) {
      ls.connectionOptions.stalledTimeout = value
    }
    
    if let param = arguments["sessionRecoveryTimeout"], let value = Millis(param) {
      ls.connectionOptions.sessionRecoveryTimeout = value
    }
    
    if let param = arguments["keepaliveInterval"], let value = Millis(param) {
      ls.connectionOptions.keepaliveInterval = value
    }
    
    if let param = arguments["pollingInterval"], let value = Millis(param) {
      ls.connectionOptions.pollingInterval = value
    }
    
    if let param = arguments["reverseHeartbeatInterval"], let value = Millis(param) {
      ls.connectionOptions.reverseHeartbeatInterval = value
    }
    
    if let param = arguments["maxBandwidth"] {
      if param == "unlimited" {
        ls.connectionOptions.requestedMaxBandwidth = .unlimited
      } else if let bw = Double(param) {
        ls.connectionOptions.requestedMaxBandwidth = .limited(bw)
      }
    }
    
    if let param = arguments["httpExtraHeaders"] {
      // example: {h1:v1,h2:v2}
      var headers: [String:String] = [:]
      let startIndex = param.index(param.startIndex, offsetBy: 1)
      let endIndex = param.index(param.endIndex, offsetBy: -1)
      let values = param[startIndex..<endIndex]
      for pair in values.split(separator: ",") {
        let comps = pair.split(separator: ":")
        let key = comps[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let val = comps[1].trimmingCharacters(in: .whitespacesAndNewlines)
        headers[key] = val
      }
      ls.connectionOptions.HTTPExtraHeaders = headers
    }
    
    if let param = arguments["httpExtraHeadersOnSessionCreationOnly"], let value = Bool(param) {
      ls.connectionOptions.HTTPExtraHeadersOnSessionCreationOnly = value
    }
    
    if arguments["proxy"] != nil {
      os_log("%@", log: category, type: .error, "Proxy not supported")
    }
    
    clientListener = MyClientListener(clientstatus_channel, "-1")
    ls.addDelegate(clientListener)
    ls.connect();
    
    result(getStatus())
  }
  
  func getStatus() -> String {
    return ls.status.rawValue
  }
}

class LightstreamerBridge {
  let category = OSLog(subsystem: "com.lightstreamer", category: "lightstreamer.flutter")

  // WARNING: Potential memory leak. Clients are added to the map but not removed.
  var _clientMap: [String:LightstreamerClient] = [:]
  var _listenerMap: [String:MyClientListener] = [:]
  
  var _subIdGenerator = 0
  var _subMap: [String:Subscription] = [:]
  var _subListenerMap: [String:MySubListener] = [:]
  
  var _mpnSubIdGenerator = 0
  var _mpnSubMap: [String:MPNSubscription] = [:]
  var _mpnSubListenerMap: [String:MyMpnSubListener] = [:]
  
  var _msgListenerMap: [String:MyClientMessageListener] = [:]
  
  func hasId(_ call: FlutterMethodCall) -> Bool {
    if let arguments = call.arguments as? [String:Any] {
      return arguments["id"] != nil
    }
    return false
  }
  
  func connect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ clientstatus_channel: FlutterBasicMessageChannel) {
    let arguments = call.arguments as! [String:String]
    let id = arguments["id"]!
    let ls = getClient(id)
    
    if let param = arguments["serverAddress"] {
      ls.connectionDetails.serverAddress = param
    } else {
      result(FlutterError(code: "11", message: "No server address was configured", details: nil))
      return // early exit
    }
    
    if let param = arguments["adapterSet"] {
      ls.connectionDetails.adapterSet = param
    } else {
      result(FlutterError(code: "12", message: "No adapter set id was configured", details: nil))
      return // early exit
    }
    
    if !ls.delegates.isEmpty {
      ls.removeDelegate(ls.delegates[0])
    }
    
    if let param = arguments["user"] {
      ls.connectionDetails.user = param
    }
    
    if let param = arguments["password"] {
      ls.connectionDetails.setPassword(param)
    }
    
    if let param = arguments["forcedTransport"] {
      ls.connectionOptions.forcedTransport = TransportSelection(rawValue: param)!
    }
    
    if let param = arguments["firstRetryMaxDelay"], let value = Millis(param) {
      ls.connectionOptions.firstRetryMaxDelay = value
    }
    
    if let param = arguments["retryDelay"], let value = Millis(param) {
      ls.connectionOptions.retryDelay = value
    }
    
    if let param = arguments["idleTimeout"], let value = Millis(param) {
      ls.connectionOptions.idleTimeout = value
    }
    
    if let param = arguments["reconnectTimeout"], let value = Millis(param) {
      ls.connectionOptions.reconnectTimeout = value
    }
    
    if let param = arguments["stalledTimeout"], let value = Millis(param) {
      ls.connectionOptions.stalledTimeout = value
    }
    
    if let param = arguments["sessionRecoveryTimeout"], let value = Millis(param) {
      ls.connectionOptions.sessionRecoveryTimeout = value
    }
    
    if let param = arguments["keepaliveInterval"], let value = Millis(param) {
      ls.connectionOptions.keepaliveInterval = value
    }
    
    if let param = arguments["pollingInterval"], let value = Millis(param) {
      ls.connectionOptions.pollingInterval = value
    }
    
    if let param = arguments["reverseHeartbeatInterval"], let value = Millis(param) {
      ls.connectionOptions.reverseHeartbeatInterval = value
    }
    
    if let param = arguments["maxBandwidth"] {
      if param == "unlimited" {
        ls.connectionOptions.requestedMaxBandwidth = .unlimited
      } else if let bw = Double(param) {
        ls.connectionOptions.requestedMaxBandwidth = .limited(bw)
      }
    }
    
    if let param = arguments["httpExtraHeaders"] {
      // example: {h1:v1,h2:v2}
      var headers: [String:String] = [:]
      let startIndex = param.index(param.startIndex, offsetBy: 1)
      let endIndex = param.index(param.endIndex, offsetBy: -1)
      let values = param[startIndex..<endIndex]
      for pair in values.split(separator: ",") {
        let comps = pair.split(separator: ":")
        let key = comps[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let val = comps[1].trimmingCharacters(in: .whitespacesAndNewlines)
        headers[key] = val
      }
      ls.connectionOptions.HTTPExtraHeaders = headers
    }
    
    if let param = arguments["httpExtraHeadersOnSessionCreationOnly"], let value = Bool(param) {
      ls.connectionOptions.HTTPExtraHeadersOnSessionCreationOnly = value
    }
    
    if arguments["proxy"] != nil {
      os_log("%@", log: category, type: .error, "Proxy not supported")
    }
    
    let clientListener = _listenerMap[id] ?? MyClientListener(clientstatus_channel, id)
    if _listenerMap.updateValue(clientListener, forKey: id) == nil {
      // add at most one delegate
      ls.addDelegate(clientListener)
    }
    ls.connect();
    
    result(ls.status.rawValue)
  }
  
  func disconnect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    let id = arguments["id"]!
    let ls = getClient(id)
    
    ls.disconnect()
    _listenerMap.removeValue(forKey: id)
      
    result(ls.status.rawValue)
  }
  
  func getClient(_ id: String) -> LightstreamerClient {
    let ls = _clientMap[id] ?? LightstreamerClient(serverAddress: nil, adapterSet: nil)
    _clientMap.updateValue(ls, forKey: id)
    return ls
  }
  
  func getStatus(_ call: FlutterMethodCall) -> String {
    let arguments = call.arguments as! [String:String]
    let id = arguments["id"]!
    let ls = getClient(id)
    
    return ls.status.rawValue
  }
  
  func subscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ subscribedata_channel: FlutterBasicMessageChannel) {
    let arguments = call.arguments as! [String:Any]
    let id = arguments["id"] as! String
    let ls = getClient(id)
    
    let mode = Subscription.Mode(rawValue: arguments["mode"] as! String)!
    let sub = Subscription(subscriptionMode: mode)
    
    if let itemList = arguments["itemList"] as? [String] {
      sub.items = itemList
    }
    if let itemGroup = arguments["itemGroup"] as? String {
      sub.itemGroup = itemGroup
    }
    if let fieldList = arguments["fieldList"] as? [String] {
      sub.fields = fieldList
    }
    if let fieldSchema = arguments["fieldSchema"] as? String {
      sub.fieldSchema = fieldSchema
    }
        
    if let param = arguments["dataAdapter"], let value = param as? String {
      sub.dataAdapter = value
    }
    
    if let param = arguments["requestedSnapshot"], let value = param as? String {
      if value == "yes" {
        sub.requestedSnapshot = .yes
      } else if value == "no" {
        sub.requestedSnapshot = .no
      } else if let len = Int(value) {
        sub.requestedSnapshot = .length(len)
      }
    }
    
    if let param = arguments["requestedBufferSize"], let value = param as? String {
      if value == "unlimited" {
        sub.requestedBufferSize = .unlimited
      } else if let size = Int(value) {
        sub.requestedBufferSize = .limited(size)
      }
    }
    
    if let param = arguments["requestedMaxFrequency"], let value = param as? String {
      if value == "unlimited" {
        sub.requestedMaxFrequency = .unlimited
      } else if value == "unfiltered" {
        sub.requestedMaxFrequency = .unfiltered
      } else if let freq = Double(value) {
        sub.requestedMaxFrequency = .limited(freq)
      }
    }
    
    if let param = arguments["commandSecondLevelDataAdapter"], let value = param as? String {
      sub.commandSecondLevelDataAdapter = value
    }
    
    if let param = arguments["commandSecondLevelFields"], let value = param as? String {
      sub.commandSecondLevelFields = value.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
    }
    
    let subId = "subid_\(_subIdGenerator += 1)"
    
    let subListener = MySubListener(subscribedata_channel, subId, sub)
    _subMap[subId] = sub
    _subListenerMap[subId] = subListener
    
    sub.addDelegate(subListener)
    ls.subscribe(sub)
    
    result(subId)
  }
  
  func unsubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    let id = arguments["id"]!
    let ls = getClient(id)
    
    if let sub_id = arguments["sub_id"] {
      
      let sub = _subMap.removeValue(forKey: sub_id)
      if sub != nil {
        ls.unsubscribe(sub!)
        _subListenerMap.removeValue(forKey: sub_id)
      }
      
      result("Ok")
    } else {
      result(FlutterError(code: "5", message: "No Sub Id specified", details: nil))
    }
  }
  
  func sendMessageExt(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ messagestatus_channel: FlutterBasicMessageChannel) {
    let arguments = call.arguments as! [String:Any]
    let id = arguments["id"] as! String
    let ls = getClient(id)
    
    let msgId = arguments["msg_id"] as! String
    
    if let msg = arguments["message"] as? String {
      var timeout = -1
      var seq: String? = nil
      var enq = false
      var addListnr = false
      
      if let param = arguments["sequence"] {
        if let sequence = param as? String {
          seq = sequence
        } else {
          seq = nil
        }
      }
      
      if let param = arguments["delayTimeout"] as? Millis {
        timeout = param
      }
      
      if let param = arguments["enqueueWhileDisconnected"] as? Bool {
        enq = param
      }
      
      if let param = arguments["listener"] as? Bool  {
        addListnr = param
      }
      
      if addListnr {
        let msgListener = MyClientMessageListener(messagestatus_channel, msgId, self)
        _msgListenerMap[msgId] = msgListener
        ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: msgListener, enqueueWhileDisconnected: enq)
      } else {
        ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: nil, enqueueWhileDisconnected: enq)
      }
      
      result("Ok")
      
    } else {
      result(FlutterError(code: "9", message: "No message", details: nil))
    }
  }
  
  func disposeMessageListener(_ msgId: String) {
    _msgListenerMap.removeValue(forKey: msgId)
  }
  
  func mpnSubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult, _ subscribedata_channel: FlutterBasicMessageChannel) {
    let arguments = call.arguments as! [String:Any]
    let id = arguments["id"] as! String
    let ls = getClient(id)
    
    if let param = arguments["mode"], let value = param as? String {
      let mode = MPNSubscription.Mode(rawValue: value)!
      
      if let param = arguments["itemList"], let value = param as? [String] {
        let itemArr = value
      
        if let param = arguments["fieldList"], let value = param as? [String] {
          let sub_id = "mpnsubid_\(_mpnSubIdGenerator += 1)"
          
          let fieldArr = value
          
          let sub = MPNSubscription(subscriptionMode: mode, items: itemArr, fields: fieldArr)
          
          if let param = arguments["dataAdapter"], let value = param as? String {
            sub.dataAdapter = value
          }
          
          if let param = arguments["requestedBufferSize"], let value = param as? String {
            if value == "unlimited" {
              sub.requestedBufferSize = .unlimited
            } else if let size = Int(value) {
              sub.requestedBufferSize = .limited(size)
            }
          }
          
          if let param = arguments["requestedMaxFrequency"], let value = param as? String {
            if value == "unlimited" {
              sub.requestedMaxFrequency = .unlimited
            } else if let freq = Double(value) {
              sub.requestedMaxFrequency = .limited(freq)
            }
          }
          
          if let param = arguments["notificationFormat"], let value = param as? String {
            sub.notificationFormat = value
          }
          
          if let param = arguments["triggerExpression"], let value = param as? String {
            sub.triggerExpression = value
          }
          
          let mpnListener = MyMpnSubListener(subscribedata_channel, sub_id)
          _mpnSubMap[sub_id] = sub
          _mpnSubListenerMap[sub_id] = mpnListener
          
          sub.addDelegate(mpnListener)
          ls.subscribeMPN(sub, coalescing: true)
          
          result(sub_id)
          
        } else {
          result(FlutterError(code: "1", message: "No Fields List specified", details: nil))
        }
      } else {
        result(FlutterError(code: "2", message: "No Items List specified", details: nil))
      }
    } else {
      result(FlutterError(code: "3", message: "No subscription mode specified", details: nil))
    }
  }
  
  func mpnUnsubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    let id = arguments["id"]!
    let ls = getClient(id)
    
    if let sub_id = arguments["sub_id"] {
      
      let sub = _mpnSubMap.removeValue(forKey: sub_id)
      if sub != nil {
        ls.unsubscribeMPN(sub!)
        _mpnSubListenerMap.removeValue(forKey: sub_id)
      }
      
      result("Ok")
    } else {
      result(FlutterError(code: "4", message: "No Sub Id specified", details: nil))
    }
  }
}
