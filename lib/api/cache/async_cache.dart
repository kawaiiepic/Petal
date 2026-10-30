import 'dart:collection';

/// Bounded, expiring request cache. Pending work is shared; failures are retried.
class AsyncCache<K, V> {
  final Duration ttl;
  final int maxEntries;
  final DateTime Function() _now;
  final _entries = LinkedHashMap<K, _CacheEntry<V>>();

  AsyncCache({
    required this.ttl,
    this.maxEntries = 256,
    DateTime Function()? now,
  }) : assert(maxEntries > 0),
       _now = now ?? DateTime.now;

  Future<V> get(K key, Future<V> Function() load, {bool force = false}) {
    final existing = _entries[key];
    if (existing != null &&
        (existing.pending || (!force && _now().isBefore(existing.expiresAt)))) {
      _entries.remove(key);
      _entries[key] = existing;
      return existing.future;
    }
    final entry = _CacheEntry<V>();
    entry.expiresAt = _now().add(ttl);
    entry.future = Future<V>.sync(load).then(
      (value) {
        entry.pending = false;
        entry.expiresAt = _now().add(ttl);
        return value;
      },
      onError: (Object error, StackTrace stack) {
        if (identical(_entries[key], entry)) _entries.remove(key);
        Error.throwWithStackTrace(error, stack);
      },
    );
    _entries.remove(key);
    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return entry.future;
  }

  void invalidate(K key) => _entries.remove(key);
  void clear() => _entries.clear();
}

class _CacheEntry<V> {
  late Future<V> future;
  late DateTime expiresAt;
  bool pending = true;
}
