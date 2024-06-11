import Foundation
import LightstreamerClient

class MyClientListener: ClientDelegate {
  let channel: FlutterBasicMessageChannel
  let clientId: String
  
  init(_ clientstatus_channel: FlutterBasicMessageChannel, _ clientId: String) {
    self.channel = clientstatus_channel
    self.clientId = clientId
  }
  
  func clientDidRemoveDelegate(_ client: LightstreamerClient) {}
  
  func clientDidAddDelegate(_ client: LightstreamerClient) {}
  
  func client(_ client: LightstreamerClient, didReceiveServerError errorCode: Int, withMessage errorMessage: String) {
    let json = toJson("ServerError:\(errorCode)\(errorMessage)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func client(_ client: LightstreamerClient, didChangeStatus status: LightstreamerClient.Status) {
    let json = toJson("StatusChange:\(status)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func client(_ client: LightstreamerClient, didChangeProperty property: String) {
    let json = toJson("PropertyChange:\(property)")
    DispatchQueue.main.async {
      self.channel.sendMessage(json)
    }
  }
  
  func toJson(_ value: String) -> String {
    let msg = ["id": clientId, "value": value]
    let encoder = JSONEncoder()
    let data = try! encoder.encode(msg)
    return String(data: data, encoding: .utf8)!
  }
}
