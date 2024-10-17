/// A kind of weak map where the values are held in weak references.
/// Periodically, the map must be cleaned to remove the cleared weak references.
class MyWeakMap<V extends Object> {
  // NB an Expando cannot be used because the keys are strings
  final Map<String, WeakReference<V>> _map = {};

  V? operator[](String key) {
    return _map[key]?.target;
  }

  void operator[]=(String key, V value) {
    _map[key] = WeakReference(value);
  }

  int get length => _map.length;

  /// Removes and returns the keys that map to cleared values.
  List<String> clean() {
    var res = _map.entries.where((e) => e.value.target == null).map((e) => e.key).toList();
    _map.removeWhere((_, value) => value.target == null);
    return res;
  }
}