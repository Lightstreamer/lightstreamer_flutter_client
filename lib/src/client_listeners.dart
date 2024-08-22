import 'package:lightstreamer_flutter_client/src/client.dart';

class ClientListener {
  void onStatusChange(String status) {}
  void onPropertyChange(String property) {}
  void onServerError(int errorCode, String errorMessage) {}
  void onListenEnd() {}
  void onListenStart() {}
}

class SubscriptionListener {
  void onClearSnapshot(String itemName, int itemPos) {}
  void onCommandSecondLevelItemLostUpdates(int lostUpdates, String key) {}
  void onCommandSecondLevelSubscriptionError(int errorCode, String errorMessage, String key) {}
  void onEndOfSnapshot(String itemName, int itemPos) {}
  void onItemLostUpdates(String itemName, int itemPos, int lostUpdates) {}
  void onItemUpdate(ItemUpdate update) {}
  void onListenEnd() {}
  void onListenStart() {}
  void onRealMaxFrequency(String? frequency) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onUnsubscription() {}
}

class ClientMessageListener {
  void onAbort(String originalMessage, bool sentOnNetwork) {}
  void onDeny(String originalMessage, int errorCode, String errorMessage) {}
  void onDiscarded(String originalMessage) {}
  void onError(String originalMessage) {}
  void onProcessed(String originalMessage, String response) {}
}

class MpnDeviceListener {
  void onListenEnd() {}
  void onListenStart() {}
  void onRegistered() {}
  void onRegistrationFailed(int errorCode, String errorMessage) {}
  void onResumed() {}
  void onStatusChanged(String status, int timestamp) {}
  void onSubscriptionsUpdated() {}
  void onSuspended() {}
}

class MpnSubscriptionListener {
  void onListenEnd() {}
  void onListenStart() {}
  void onModificationError(int errorCode, String errorMessage, String propertyName) {}
  void onPropertyChanged(String propertyName) {}
  void onStatusChanged(String status, int timestamp) {}
  void onSubscription() {}
  void onSubscriptionError(int errorCode, String errorMessage) {}
  void onTriggered() {}
  void onUnsubscription() {}
  void onUnsubscriptionError(int errorCode, String errorMessage) {}
}