import 'dart:async';

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