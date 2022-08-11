import Foundation
import LightstreamerClient

class MyClientListener: ClientDelegate {
  let channel: FlutterBasicMessageChannel
  
  init(_ clientstatus_channel: FlutterBasicMessageChannel) {
    self.channel = clientstatus_channel
  }
  
  func clientDidRemoveDelegate(_ client: LightstreamerClient) {}
  
  func clientDidAddDelegate(_ client: LightstreamerClient) {}
  
  func client(_ client: LightstreamerClient, didReceiveServerError errorCode: Int, withMessage errorMessage: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("ServerError: \(errorCode) \(errorMessage)")
    }
  }
  
  func client(_ client: LightstreamerClient, didChangeStatus status: LightstreamerClient.Status) {
    DispatchQueue.main.async {
      self.channel.sendMessage("StatusChange: \(status)")
    }
  }
  
  func client(_ client: LightstreamerClient, didChangeProperty property: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("PropertyChange: \(property)")
    }
  }
}
