import Foundation
import LightstreamerClient

class MyMpnSubListener: MPNSubscriptionDelegate {
  let channel: FlutterBasicMessageChannel
  let subId: String
  
  init(_ channel: FlutterBasicMessageChannel, _ subId: String) {
    self.channel = channel
    self.subId = subId
  }
  
  func mpnSubscriptionDidAddDelegate(_ subscription: MPNSubscription) {
    
  }
  
  func mpnSubscriptionDidRemoveDelegate(_ subscription: MPNSubscription) {
    
  }
  
  func mpnSubscriptionDidSubscribe(_ subscription: MPNSubscription) {
    
  }
  
  func mpnSubscriptionDidUnsubscribe(_ subscription: MPNSubscription) {
    
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailSubscriptionWithErrorCode code: Int, message: String?) {
    
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailUnsubscriptionWithErrorCode code: Int, message: String?) {
    
  }
  
  func mpnSubscriptionDidTrigger(_ subscription: MPNSubscription) {
    
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didChangeStatus status: MPNSubscription.Status, timestamp: Int64) {
    
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didChangeProperty property: String) {
    
  }
  
  func mpnSubscription(_ subscription: MPNSubscription, didFailModificationWithErrorCode code: Int, message: String?, property: String) {
    
  }
}
