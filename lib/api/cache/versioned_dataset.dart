import 'dart:async';
import 'dart:convert';

/// A profile/server-scoped snapshot. Revalidation never clears visible data.
class VersionedDataset<T> {
  final String name;
  final String versionField;
  final Object? Function(T) encode;
  final T Function(Object?) decode;
  final Duration? maxAge;
  final String Function() server;
  final bool Function(String) isCurrentScope;
  final Future<Map<String, dynamic>?> Function(String, String) versions;
  final Future<String?> Function(String) read;
  final Future<void> Function(String, String) write;
  final Future<void> Function(String) remove;
  final DateTime Function() now;
  final void Function(String) invalidateVersions;
  Future<void> _writes = Future.value();
  final _stored = <String, Map<String, dynamic>>{};
  final _values = <String, T>{};
  final _reads = <String, Future<T?>>{};
  final _pending = <String, Future<T>>{};
  final _revisions = <String, int>{};
  final _checked = <String, DateTime>{};
  final _dirty = <String>{};

  VersionedDataset({required this.name, required this.versionField,
    required this.encode, required this.decode, this.maxAge,
    required this.server, required this.isCurrentScope, required this.versions,
    required this.read, required this.write, required this.remove,
    required this.invalidateVersions, DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  String _key(String scope) =>
      'petal.dataset.v1.${Uri.encodeComponent('${server()}|$scope|$name')}';

  void invalidate(String scope) {
    _revisions[scope] = (_revisions[scope] ?? 0) + 1;
    _dirty.add(scope);
    _checked.remove(scope);
    invalidateVersions(scope);
  }

  Future<T?> _read(String scope) async {
    if (_values.containsKey(scope)) return _values[scope];
    return _reads.putIfAbsent(scope, () async {
      String? raw;
      try { raw = await read(_key(scope)); } catch (_) { return null; }
      if (raw == null) return null;
      try {
        final blob = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (blob['schema'] != 1 || blob['scope'] != scope ||
            blob['server'] != server() || blob['saved_at'] is! int) return null;
        final value = decode(blob['data']);
        _stored[scope] = blob;
        _values[scope] = value;
        return value;
      } catch (_) {
        await remove(_key(scope));
        return null;
      }
    });
  }

  Future<T> get({required String scope, required String profileId,
    required Future<T> Function() load, required void Function(T) onUpdated,
    bool force = false}) async {
    final cached = await _read(scope);
    if (cached != null && !force && !_dirty.contains(scope)) {
      final last = _checked[scope];
      if (last == null || now().difference(last) >= const Duration(seconds: 30)) {
        unawaited(_refresh(scope, profileId, load, onUpdated)
            .then<void>((_) {}).catchError((Object _) {}));
      }
      return cached;
    }
    return _refresh(scope, profileId, load, onUpdated);
  }

  Future<T> _refresh(String scope, String profileId, Future<T> Function() load,
      void Function(T) onUpdated) {
    final revision = _revisions[scope] ?? 0;
    final requestKey = '$scope|$revision';
    return _pending.putIfAbsent(requestKey, () async {
      try {
        final stamp = await versions(scope, profileId);
        if (!isCurrentScope(scope) || (_revisions[scope] ?? 0) != revision) {
          throw StateError('Profile or data changed while checking versions');
        }
        final blob = _stored[scope];
        final fresh = maxAge == null || (blob != null &&
            now().millisecondsSinceEpoch - (blob['saved_at'] as int) <
                maxAge!.inMilliseconds);
        if (!_dirty.contains(scope) && stamp != null && blob != null &&
            blob['generation'] == stamp['generation'] &&
            blob['version'] == stamp[versionField] && fresh &&
            _values.containsKey(scope)) {
          _checked[scope] = now();
          _dirty.remove(scope);
          return _values[scope] as T;
        }
        final value = await load();
        if (!isCurrentScope(scope) ||
            (_revisions[scope] ?? 0) != revision) {
          throw StateError('Profile or data changed while refreshing');
        }
        final next = <String, dynamic>{
          'schema': 1, 'scope': scope, 'server': server(),
          'generation': stamp?['generation'],
          'version': stamp?[versionField],
          'saved_at': now().millisecondsSinceEpoch,
          'data': encode(value),
        };
        // One preference value keeps the snapshot and its version together.
        final save = _writes.catchError((Object _) {}).then((_) async {
          if (!isCurrentScope(scope) || (_revisions[scope] ?? 0) != revision) {
            throw StateError('Profile or data changed while saving');
          }
          var saved = false;
          try {
            await write(_key(scope), jsonEncode(next));
            saved = true;
          } catch (_) {
            // A full/unavailable disk must not hide successfully fetched data.
          }
          if (!isCurrentScope(scope) || (_revisions[scope] ?? 0) != revision) {
            if (saved) await remove(_key(scope));
            throw StateError('Snapshot invalidated while saving');
          }
          _stored[scope] = next;
          _values[scope] = value;
          _checked[scope] = now();
          _dirty.remove(scope);
          onUpdated(value);
        });
        _writes = save;
        await save;
        return value;
      } finally {
        _pending.remove(requestKey);
      }
    });
  }
}
