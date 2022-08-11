import Foundation
import LightstreamerClient

class MySubListener: SubscriptionDelegate {
  let channel: FlutterBasicMessageChannel
  let subId: String
  let commandMode: Bool
  
  init(_ channel: FlutterBasicMessageChannel, _ subId: String, _ commandMode: Bool) {
    self.channel = channel
    self.subId = subId
    self.commandMode = commandMode
  }
  
  func subscription(_ subscription: Subscription, didClearSnapshotForItemName itemName: String?, itemPos: UInt) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onClearSnapshot|\(itemName ?? "")|\(itemPos)")
    }
  }
  
  func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forCommandSecondLevelItemWithKey key: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onCommandSecondLevelItemLostUpdates|\(self.subId)|\(key)|\(lostUpdates)")
    }
  }
  
  func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?, forCommandSecondLevelItemWithKey key: String) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onCommandSecondLevelSubscriptionError|\(code)|\(message ?? "")|\(key)")
    }
  }
  
  func subscription(_ subscription: Subscription, didEndSnapshotForItemName itemName: String?, itemPos: UInt) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onEndOfSnapshot|\(itemName ?? "")|\(itemPos)")
    }
  }
  
  func subscription(_ subscription: Subscription, didLoseUpdates lostUpdates: UInt, forItemName itemName: String?, itemPos: UInt) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onItemLostUpdates|\(self.subId)|\(itemName ?? "")|\(itemPos)|\(lostUpdates)")
    }
  }
  
  func subscription(_ subscription: Subscription, didUpdateItem update: ItemUpdate) {
    for (uKey, uValue) in update.changedFields {
      let uItem: String
      if commandMode {
        uItem = "\(update.itemName ?? ""),\(update.value(withFieldName: "key") ?? "")"
      } else {
        uItem = update.itemName ?? ""
      }
      
      DispatchQueue.main.async {
        self.channel.sendMessage("onItemUpdate|\(self.subId)|\(uItem)|\(uKey)|\(uValue ?? "")")
      }
    }
  }
  
  func subscriptionDidRemoveDelegate(_ subscription: Subscription) {}
  
  func subscriptionDidAddDelegate(_ subscription: Subscription) {}
  
  func subscriptionDidSubscribe(_ subscription: Subscription) {}
  
  func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onSubscriptionError|\(code)|\(message ?? "")")
    }
  }
  
  func subscriptionDidUnsubscribe(_ subscription: Subscription) {}
  
  func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {}
}
