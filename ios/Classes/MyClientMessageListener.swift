import Foundation
import LightstreamerClient

class MyClientMessageListener: ClientMessageDelegate {
  let channel: FlutterBasicMessageChannel
  
  init(_ messagestatus_channel: FlutterBasicMessageChannel) {
    self.channel = messagestatus_channel
  }
  
  func client(_ client: LightstreamerClient, didAbortMessage originalMessage: String, sentOnNetwork: Bool) {
    if sentOnNetwork {
      DispatchQueue.main.async {
        self.channel.sendMessage("Abort:Sent:\(originalMessage)")
      }
    } else {
      DispatchQueue.main.async {
        self.channel.sendMessage("Abort:NotSent:\(originalMessage)")
      }
    }
  }
  
  func client(_ client: LightstreamerClient, didDenyMessage originalMessage: String, withCode code: Int, error: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("Deny:\(code):\(error):\(originalMessage)")
    }
  }
  
  func client(_ client: LightstreamerClient, didDiscardMessage originalMessage: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("Discarded:\(originalMessage)")
    }
  }
  
  func client(_ client: LightstreamerClient, didFailMessage originalMessage: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("Error:\(originalMessage)")
    }
  }
  
  func client(_ client: LightstreamerClient, didProcessMessage originalMessage: String, withResponse response: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("Processed:\(originalMessage)")
    }
  }
}
