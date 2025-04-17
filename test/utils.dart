/*
 * Copyright (C) 2022 Lightstreamer Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import 'dart:async';
import 'package:test/test.dart';
import 'package:lightstreamer_flutter_client/lightstreamer_client_web.dart';

void assertEqual<T>(T expected, T actual) => expect(actual, expected);
void assertTrue(bool cnd) => expect(cnd, isTrue);
void assertFalse(bool cnd) => expect(cnd, isFalse);
void assertNull(Object? obj) => expect(obj, isNull);
void assertNotNull(Object? obj) => expect(obj, isNotNull);

enum _State { s1, s2, s3, s4, s5, s6, s7, s8, s9, sa }

class Expectations {
  _State _state = _State.s1;
  late Completer<void> _pendingFuture;
  late String _pendingExpected;
  List<String> _queue = [];
  
  void signal([String actual = '']) {
    print('--> signal $actual');
    switch (_state) {
      case _State.s3:
        _s4(actual);
      case _State.s6 || _State.s8 || _State.s9:
       if (_pendingExpected == actual) {
        _s7(actual);
       } else {
        _s8(actual);
       }
      default:
         _s2(actual);
    }
  }

  Future<void> value([String expected = '']) {
    switch (_state) {
      case _State.s1 || _State.s4 || _State.s7:
        return _s3(expected);
      case _State.s2:
        return _s5(expected);
      case _State.s5 || _State.sa:
        if (_queue.isEmpty) {
          return _s3(expected);
        } else {
          return _s5(expected);
        }
      default:
        throw 'Unexpected value($expected) in state $_state';
    }
  }

  Future<void> until(String expected) {
    switch (_state) {
      case _State.s1 || _State.s4 || _State.s7:
        return _s6(expected);
      case _State.s2 || _State.s5 || _State.sa:
        if (_queue.contains(expected)) {
          return _sa(expected);
        } else {
          return _s9(expected);
        }
      default:
        throw 'Unexpected until($expected) in state $_state';
    }
  }

  void _s2(String actual) {
    _state = _State.s2;
    _queue.add(actual);
  }

  Future<void> _s3(String expected) {
    _state = _State.s3;
    _pendingExpected = expected;
    _pendingFuture = new Completer();
    return _pendingFuture.future;
  }

  void _s4(String actual) {
    _state = _State.s4;
    if (_pendingExpected == actual) {
      _pendingFuture.complete();
    } else {
      _pendingFuture.completeError('Expected $_pendingExpected but found $actual');
    }
  }

  Future<void> _s5(String expected) {
    _state = _State.s5;
    var actual = _queue.removeAt(0);
    if (expected == actual) {
      return Future<void>.value();
    } else {
      return Future<void>.error('Expected $expected but found $actual');
    }
  }

  Future<void> _s6(String expected) {
    _state = _State.s6;
    _pendingExpected = expected;
    _pendingFuture = new Completer();
    return _pendingFuture.future;
  }

  void _s7(String actual) {
    _state = _State.s7;
    _pendingFuture.complete();
  }

  void _s8(String actual) {
    _state = _State.s8;
  }

  Future<void> _s9(String expected) {
    _state = _State.s9;
    _queue.clear();
    _pendingExpected = expected;
    _pendingFuture = new Completer();
    return _pendingFuture.future;
  }

  Future<void> _sa(String expected) {
    _state = _State.sa;
    var actual = _queue.removeAt(0);
    while (expected != actual) {
      actual = _queue.removeAt(0);
    }
    return Future.value();
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
