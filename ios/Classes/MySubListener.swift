import Foundation
import LightstreamerClient

class MySubListener: SubscriptionDelegate {
  let channel: FlutterBasicMessageChannel
  let subId: String
  let sub: Subscription
  var isCommandMode: Bool!
  var hasFieldNames: Bool!
  var keyPosition: Int!
  
  init(_ channel: FlutterBasicMessageChannel, _ subId: String, _ sub: Subscription) {
    self.channel = channel
    self.subId = subId
    self.sub = sub
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
    var uItem = ""
    if isCommandMode {
      if hasFieldNames {
        uItem = "\(update.itemName ?? "\(update.itemPos)"),\(update.value(withFieldName: "key") ?? "")"
      } else {
        uItem = "\(update.itemName ?? "\(update.itemPos)"),\(update.value(withFieldPos: keyPosition) ?? "")"
      }
    } else {
      uItem = update.itemName ?? "\(update.itemPos)"
    }
    
    if hasFieldNames {
      for (uKey, uValue) in update.changedFields {
        DispatchQueue.main.async {
          self.channel.sendMessage("onItemUpdate|\(self.subId)|\(uItem)|\(uKey)|\(uValue ?? "")")
        }
      }
    } else {
      for (uKey, uValue) in update.changedFieldsByPositions {
        DispatchQueue.main.async {
          self.channel.sendMessage("onItemUpdate|\(self.subId)|\(uItem)|\(uKey)|\(uValue ?? "")")
        }
      }
    }
  }
  
  func subscriptionDidRemoveDelegate(_ subscription: Subscription) {}
  
  func subscriptionDidAddDelegate(_ subscription: Subscription) {}
  
  func subscriptionDidSubscribe(_ subscription: Subscription) {
    self.isCommandMode = sub.mode == .COMMAND
    self.hasFieldNames = sub.fields != nil
    self.keyPosition = sub.keyPosition
  }
  
  func subscription(_ subscription: Subscription, didFailWithErrorCode code: Int, message: String?) {
    DispatchQueue.main.async {
      self.channel.sendMessage("onSubscriptionError|\(code)|\(message ?? "")")
    }
  }
  
  func subscriptionDidUnsubscribe(_ subscription: Subscription) {}
  
  func subscription(_ subscription: Subscription, didReceiveRealFrequency frequency: RealMaxFrequency?) {}
}
