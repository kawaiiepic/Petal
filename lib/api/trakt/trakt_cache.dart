import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TraktCache {
  static Directory? _cacheDir;

  static const String userProfile = '/users/me';
  static const String syncWatched = '/sync/watched';
  static const String showProgress = '/shows/%s/progress/watched';

  static Future<Directory> _getDir() async {
    _cacheDir ??= Directory('${(await getApplicationCacheDirectory()).path}/trakt');
    if (!await _cacheDir!.exists()) await _cacheDir!.create(recursive: true);
    return _cacheDir!;
  }

  static Future<File> _file(String key) async {
    final dir = await _getDir();
    return File('${dir.path}/${key.replaceAll('/', '_')}.json');
  }

  static Future<void> set(String key, dynamic value) async {
    if (kIsWeb) {
    } else {
      final file = await _file(key);
      await file.writeAsString(jsonEncode({'invalidated': false, 'cachedAt': DateTime.now().toIso8601String(), 'data': value}));
    }
  }

  static Future<T?> get<T>(String key, {Duration? maxAge}) async {
    if (kIsWeb) {
      return null;
    } else {
      print("Getting ${key}");
      final file = await _file(key);
      if (!await file.exists()) return null;

      final json = jsonDecode(await file.readAsString());

      if (json['invalidate'] == true) {
        return null;
      }
      if (maxAge != null) {
        final cachedAt = DateTime.parse(json['cachedAt']);
        if (DateTime.now().difference(cachedAt) > maxAge) {
          return null;
        }
      }

      return json['data'] as T?;
    }
  }

  static Future<DateTime?> cachedAt(String key) async {
    if (kIsWeb) {
      return null;
    } else {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return DateTime.parse(json['cachedAt']);
    }
  }

  static Future<void> invalidate(String key) async {
    final file = await _file(key);
    if (!await file.exists()) return;

    final json = jsonDecode(await file.readAsString());
    json['invalidated'] = true;
    await file.writeAsString(jsonEncode(json));
  }

  static Future<void> clear() async {
    final dir = await _getDir();
    await dir.delete(recursive: true);
  }
}
