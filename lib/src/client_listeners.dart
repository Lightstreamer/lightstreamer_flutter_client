import 'package:lightstreamer_flutter_client/src/item_update.dart';

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
  void onListenEnd(void dummy) {}
  void onListenStart(void dummy) {}
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