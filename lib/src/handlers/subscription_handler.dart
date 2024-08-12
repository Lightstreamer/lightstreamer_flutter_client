import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client.dart';

class SubscriptionHandler {
  // TODO possible memory leak
  Map<String, Subscription> _subMap = {};

  void addSubscription(String subId, Subscription sub) {
    // TODO what if sub is already there?
    _subMap[subId] = sub;
  }

  void removeSubscription(String subId) {
    _subMap.remove(subId);
  }

  Subscription? getSubscription(String subId) {
    return _subMap[subId];
  }

  void handle(String method, MethodCall call) {
    switch (method) {
      case "onItemUpdate":
        _onItemUpdate(call);
      case "onSubscriptionError":
        _onSubscriptionError(call);
      case "onClearSnapshot":
        _onClearSnapshot(call);
      case "onCommandSecondLevelItemLostUpdates":
        _onCommandSecondLevelItemLostUpdates(call);
      case "onCommandSecondLevelSubscriptionError":
        _onCommandSecondLevelSubscriptionError(call);
      case "onEndOfSnapshot":
        _onEndOfSnapshot(call);
      case "onItemLostUpdates":
        _onItemLostUpdate(call);
      case "onSubscription":
        _onSubscription(call);
      case "onUnsubscription":
        _onUnsubscription(call);
      case "onRealMaxFrequency":
        _onRealMaxFrequency(call);
      default:
        // TODO default
    }
  }

  void _onClearSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onClearSnapshot(itemName, itemPos);
      });
    }
  }

  void _onCommandSecondLevelItemLostUpdates(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int lostUpdates = arguments['lostUpdates'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelItemLostUpdates(lostUpdates, key);
      });
    }
  }

  void _onCommandSecondLevelSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int code = arguments['code'];
    String message = arguments['message'];
    String key = arguments['key'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onCommandSecondLevelSubscriptionError(code, message, key);
      });
    }
  }

  void _onEndOfSnapshot(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onEndOfSnapshot(itemName, itemPos);
      });
    }
  }

  void _onItemLostUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String itemName = arguments['itemName'];
    int itemPos = arguments['itemPos'];
    int lostUpdates = arguments['lostUpdates'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onItemLostUpdates(itemName, itemPos, lostUpdates);
      });
    }
  }

  void _onItemUpdate(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    ItemUpdate update = ItemUpdate(call);
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onItemUpdate(update);
      });
    }
  }

  void _onSubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onSubscription();
      });
    }
  }

  void _onSubscriptionError(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    int errorCode = arguments['errorCode'];
    String errorMessage = arguments['errorMessage'];
    // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onSubscriptionError(errorCode, errorMessage);
      });
    }
  }

  void _onUnsubscription(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onUnsubscription();
      });
    }
  }

  void _onRealMaxFrequency(MethodCall call) {
    var arguments = call.arguments;
    String subId = arguments['subId'];
    String? frequency = arguments['frequency'];
     // TODO null check
    Subscription sub = _subMap[subId]!;
    for (var l in sub.getListeners()) {
      scheduleMicrotask(() {
        l.onRealMaxFrequency(frequency);
      });
    }
  }
}