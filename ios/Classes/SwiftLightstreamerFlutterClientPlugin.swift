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
  
  let category = OSLog(subsystem: "com.lightstreamer", category: "flutter")
  
  init(_ registrar: FlutterPluginRegistrar) {
    clientstatus_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.status", binaryMessenger: registrar.messenger())
    messagestatus_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.messages", binaryMessenger: registrar.messenger())
    subscribedata_channel = FlutterBasicMessageChannel(name: "com.lightstreamer.lightstreamer_flutter_client.realtime", binaryMessenger: registrar.messenger())
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    //LightstreamerClient.setLoggerProvider(ConsoleLoggerProvider(level: ConsoleLogLevel.info))
    
    let channel = FlutterMethodChannel(name: "com.lightstreamer.lightstreamer_flutter_client.method", binaryMessenger: registrar.messenger())
    let instance = SwiftLightstreamerFlutterClientPlugin(registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    switch method {
    case "connect":
      connect(call, result)
    case "disconnect":
      disconnect(call, result)
    case "sendMessage":
      sendMessage(call, result)
    case "sendMessageExt":
      sendMessageExt(call, result)
    case "subscribe":
      subscribe(call, result)
    case "unsubscribe":
      unsubscribe(call, result)
    case "mpnSubscribe":
      mpnSubscribe(call, result)
    case "mpnUnsubscribe":
      mpnUnsubscribe(call, result)
    case "getStatus":
      result(getStatus())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  func mpnUnsubscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    
    if let sub_id = arguments["sub_id"] {
      
      let sub = activeMpnSubs.removeValue(forKey: sub_id)
      if sub != nil {
        ls.unsubscribeMPN(sub!)
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
          
          sub.addDelegate(MyMpnSubListener(subscribedata_channel, sub_id))

          ls.subscribeMPN(sub, coalescing: true)
          
          activeMpnSubs[sub_id] = sub
          
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
      }
      
      result("Ok")
    } else {
      result(FlutterError(code: "5", message: "No Sub Id specified", details: nil))
    }
  }
  
  func subscribe(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:Any]
    
    if let param = arguments["mode"], let value = param as? String {
      let mode = Subscription.Mode(rawValue: value)!
      
      if let param = arguments["itemList"], let value = param as? [String] {
        let itemArr = value
      
        if let param = arguments["fieldList"], let value = param as? [String] {
          let sub_id = "Ok\(prgs_sub)"
          prgs_sub += 1
          
          let fieldArr = value
          
          let sub = Subscription(subscriptionMode: mode, items: itemArr, fields: fieldArr)
          
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
          
          sub.addDelegate(MySubListener(subscribedata_channel, sub_id, mode == .COMMAND))

          ls.subscribe(sub)
          
          activeSubs[sub_id] = sub
          
          result(sub_id)
          
        } else {
          result(FlutterError(code: "6", message: "No Fields List specified", details: nil))
        }
      } else {
        result(FlutterError(code: "7", message: "No Items List specified", details: nil))
      }
    } else {
      result(FlutterError(code: "8", message: "No subscription mode specified", details: nil))
    }
  }
  
  func sendMessageExt(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:Any]
    if let msg = arguments["message"] as? String {
      var timeout = -1
      var seq: String? = "DEFAULT_FLUTTERPLUGIN_SEQUENCE"
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
      
      if getStatus().starts(with: "CONNECTED:") {
        if addListnr {
          let listener = MyClientMessageLisener(messagestatus_channel)
          ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: listener, enqueueWhileDisconnected: enq)
        } else {
          ls.sendMessage(msg, withSequence: seq, timeout: timeout, delegate: nil, enqueueWhileDisconnected: enq)
        }
      }
      
    } else {
      result(FlutterError(code: "9", message: "No message", details: nil))
    }
  }
  
  func sendMessage(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arguments = call.arguments as! [String:String]
    if let msg = arguments["message"] {
      if getStatus().starts(with: "CONNECTED:") {
        ls.sendMessage(msg)
      }
      
    } else {
      result(FlutterError(code: "10", message: "No message", details: nil))
    }
  }
  
  func disconnect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    if getStatus().starts(with: "CONNECTED:") {
      ls.disconnect()
      
      result(getStatus())
    } else {
      result(getStatus())
    }
  }
  
  func connect(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    if !getStatus().starts(with: "CONNECTED:") {
      
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
      
      ls.addDelegate(MyClientListener(clientstatus_channel))
      ls.connect();
      
      result(getStatus())
    } else {
      result(getStatus())
    }
  }
  
  func getStatus() -> String {
    return ls.status.rawValue
  }
}
