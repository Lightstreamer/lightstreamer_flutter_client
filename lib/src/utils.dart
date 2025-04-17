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