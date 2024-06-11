import Foundation
import LightstreamerClient

class MyClientMessageListener: ClientMessageDelegate {
  let channel: FlutterBasicMessageChannel
  let msgId: String
  
  init(_ messagestatus_channel: FlutterBasicMessageChannel, _ msgId: String) {
    self.channel = messagestatus_channel
    self.msgId = msgId
  }
  
  func client(_ client: LightstreamerClient, didAbortMessage originalMessage: String, sentOnNetwork: Bool) {
    if sentOnNetwork {
      let json = toJson("Abort:Sent:\(originalMessage)")
      DispatchQueue.main.async {
        self.channel.sendMessage(json)
      }
    } else {
      let json = toJson("Abort:NotSent:\(originalMessage)")
      DispatchQueue.main.async {
        self.channel.sendMessage(json)
      }
    }
  }
  
  func client(_ client: LightstreamerClient, didDenyMessage originalMessage: String, withCode code: Int, error: String) {
    let json = toJson("Deny:\(code):\(error):\(originalMessage)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func client(_ client: LightstreamerClient, didDiscardMessage originalMessage: String) {
    let json = toJson("Discarded:\(originalMessage)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func client(_ client: LightstreamerClient, didFailMessage originalMessage: String) {
    let json = toJson("Error:\(originalMessage)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func client(_ client: LightstreamerClient, didProcessMessage originalMessage: String, withResponse response: String) {
      var msg = "Processed:\(originalMessage)"
      if (!response.isEmpty) {
          msg += "\nResponse:\(response)"
      }
      let json = toJson(msg)
      DispatchQueue.main.async {
          self.channel.sendMessage(json)
      }
  }
  
  func toJson(_ value: String) -> String {
    let msg = ["id": msgId, "value": value]
    let encoder = JSONEncoder()
    let data = try! encoder.encode(msg)
    return String(data: data, encoding: .utf8)!
  }
}
