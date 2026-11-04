import 'dart:async';
import 'dart:convert';

import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small title responses, shared by collection rows and persisted across launches.
class CollectionMetadata {
  static final Map<String, Map<String, dynamic>> _data = {};
  static final Map<String, Future<Object>> _pending = {};
  static Future<void>? _restore;
  static Future<void> _saves = Future.value();
  static Timer? _saveTimer;
  static const _ttl = Duration(hours: 6);

  static String _key(int id, MediaType type) =>
      '${Api.ServerUrl}:${type.name}:$id';
  static Object _decode(Map<String, dynamic> row, MediaType type) {
    final json = Map<String, dynamic>.from(row['data'] as Map);
    return type == MediaType.show
        ? TmdbShow.fromJson(json)
        : TmdbMovie.fromJson(json);
  }

  static Object? peek(int id, MediaType type) {
    final row = _data[_key(id, type)];
    return row == null ? null : _decode(row, type);
  }

  static Future<void> restore() => _restore ??= () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('collection_metadata_v1');
      if (raw == null) return;
      final rows = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in rows.entries) {
        try {
          final row = Map<String, dynamic>.from(entry.value as Map);
          final type = entry.key.split(':').reversed.elementAt(1) == 'show'
              ? MediaType.show : MediaType.movie;
          _decode(row, type);
          _data.putIfAbsent(entry.key, () => row);
        } catch (_) {
          // One corrupt entry must not discard other cached titles.
        }
      }
    } catch (_) {
      // Cache storage is optional.
    }
  }();

  static Future<Object> get(int id, MediaType type) async {
    await restore();
    final key = _key(id, type);
    final row = _data[key];
    final saved = row?['saved_at'] as int? ?? 0;
    if (row != null &&
        DateTime.now().millisecondsSinceEpoch - saved < _ttl.inMilliseconds) {
      return _decode(row, type);
    }
    return _pending.putIfAbsent(key, () async {
      try {
        // No images, credits, videos or recommendations appended.
        final response = await TMDB.tmdbApi(
          '/${type == MediaType.show ? 'tv' : 'movie'}/$id',
        );
        if (response.statusCode != 200) throw StateError('Title lookup failed');
        final data = Map<String, dynamic>.from(response.data as Map);
        final next = <String, dynamic>{
          'saved_at': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        };
        final result = _decode(next, type);
        _data[key] = next;
        // Bound storage and serialize writes so an older snapshot cannot win.
        while (_data.length > 1000) {
          _data.remove(_data.keys.first);
        }
        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(milliseconds: 250), () {
          _saves = _saves.then((_) async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('collection_metadata_v1', jsonEncode(_data));
            } catch (_) {}
          });
        });
        return result;
      } catch (_) {
        if (row != null) return _decode(row, type);
        rethrow;
      } finally {
        _pending.remove(key);
      }
    });
  }
}
