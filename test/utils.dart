import 'dart:async';
import 'package:test/test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

void equals<T>(T expected, T actual) {
  expect(actual, expected);
}

enum _State { stStart, stAdd, stPop, stCreateFuture, stCompleteFuture}

class Expectations {
  _State _state = _State.stStart;
  late Completer<void> _pendingFuture;
  late String _pendingExpected;
  List<String> _queue = [];
  
  void signal([String actual = '']) {
    print('--> signal $actual');
    switch (_state) {
      case _State.stCreateFuture:
        _state = _State.stCompleteFuture;
        if (_pendingExpected == actual) {
          _pendingFuture.complete();
        } else {
          _pendingFuture.completeError('Expected $_pendingExpected but found $actual');
        }
      default:
        _state = _State.stAdd;
        _queue.add(actual);
    }
  }

  Future<void> value([String expected = '']) {
    switch (_state) {
      case _State.stStart || _State.stCompleteFuture:
       _state = _State.stCreateFuture;
       _pendingExpected = expected;
       _pendingFuture = new Completer();
       return _pendingFuture.future;
      case _State.stAdd || _State.stPop:
        if (_queue.isEmpty) {
          _state = _State.stCreateFuture;
          _pendingExpected = expected;
          _pendingFuture = new Completer();
          return _pendingFuture.future;
        } else {
          _state = _State.stPop;
          var actual = _queue.removeAt(0);
          if (expected != actual) {
            return Future<void>.error('Expected $expected but found $actual');
          }
          return Future<void>.value();
        }
      default:
        throw 'Unexpected case $_state';
    }
  }
}

class BaseClientListener extends ClientListener {
  void Function(String)? fStatusChange;
  void onStatusChange(String status) => fStatusChange?.call(status);
  void Function(int, String)? fServerError;
  void onServerError(int code, String msg) => fServerError?.call(code, msg);
  void Function(String)? fPropertyChange;
  void onPropertyChange(String property) => fPropertyChange?.call(property);
}

class BaseSubscriptionListener extends SubscriptionListener {
  void Function()? fSubscription;
  void onSubscription() => fSubscription?.call();
  void Function(int, String)? fSubscriptionError;
  void onSubscriptionError(int code, String msg) => fSubscriptionError?.call(code, msg);
  void Function(ItemUpdate)? fItemUpdate;
  void onItemUpdate(ItemUpdate update) => fItemUpdate?.call(update);
  void Function()? fUnsubscription;
  void onUnsubscription() => fUnsubscription?.call();
  void Function(String, int)? fClearSnapshot;
  void onClearSnapshot(String item, int pos) => fClearSnapshot?.call(item, pos);
  void Function(String?)? fRealMaxFrequency;
  void onRealMaxFrequency(String? frequency) => fRealMaxFrequency?.call(frequency);
  void Function(String, int)? fEndOfSnapshot;
  void onEndOfSnapshot(String name, int pos) => fEndOfSnapshot?.call(name, pos);
  void Function(String, int, int)? fItemLostUpdates;
  void onItemLostUpdates(String name, int pos, int lost) => fItemLostUpdates?.call(name, pos, lost);
}

class BaseMessageListener extends ClientMessageListener {
  void Function(String, String)? fProcessed;
  void onProcessed(String msg, String resp) => fProcessed?.call(msg, resp);
  void Function(String, int, String)? fDeny;
  void onDeny(String msg, int errorCode, String errorMessage) => fDeny?.call(msg, errorCode, errorMessage);
}
