import 'dart:convert';
import 'dart:typed_data';

import 'package:petal/models/imports/import_source.dart';

/// Pure parsing shared by library import formats; performs no API writes.
abstract final class ImportFileParser {
  static int countItems(String name, Uint8List bytes, ImportSource source) {
    final lower = name.toLowerCase();

    if (shouldSkipFile(lower)) return 0;

    if (lower.endsWith('.csv') || source == ImportSource.letterboxd) {
      final lines = const LineSplitter()
          .convert(utf8.decode(bytes))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      return lines.isEmpty ? 0 : lines.length - 1;
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (source == ImportSource.simkl && decoded is Map) {
      final movies = decoded['movies'] is List
          ? decoded['movies'] as List
          : const [];

      final shows = decoded['shows'] is List
          ? decoded['shows'] as List
          : decoded['tv'] is List
          ? decoded['tv'] as List
          : const [];

      return movies.length + shows.length;
    }

    if (decoded is List) return decoded.length;

    if (decoded is Map && decoded['items'] is List) {
      return (decoded['items'] as List).length;
    }

    if (decoded is Map) {
      return [
        ...safeList(decoded['movies']),
        ...safeList(decoded['shows']),
        ...safeList(decoded['watchlist']),
        ...safeList(decoded['history']),
        ...safeList(decoded['ratings']),
      ].length;
    }

    return 0;
  }

  static bool shouldSkipFile(String lowerName) {
    return lowerName.startsWith('user-') ||
        lowerName.startsWith('hidden-') ||
        lowerName.startsWith('network-') ||
        lowerName.startsWith('likes-') ||
        lowerName.startsWith('comments-') ||
        lowerName.startsWith('notes-') ||
        lowerName.contains('playback') ||
        lowerName.contains('collaborations') ||
        lowerName.contains('last-activities') ||
        lowerName.contains('user-stats');
  }

  static ImportSource detectSource(String name, Uint8List bytes) {
    if (name.contains('letterboxd') || name.endsWith('.csv')) {
      return ImportSource.letterboxd;
    }

    if (name.contains('simkl')) return ImportSource.simkl;

    if (name.contains('trakt') ||
        name.contains('history') ||
        name.contains('watched') ||
        name.contains('watchlist') ||
        name.contains('rating')) {
      return ImportSource.trakt;
    }

    final head = utf8
        .decode(bytes.take(200).toList(), allowMalformed: true)
        .toLowerCase();

    if (head.contains('letterboxd') || head.contains('watched date')) {
      return ImportSource.letterboxd;
    }

    if (head.contains('"simkl"') || head.contains('simkl_id')) {
      return ImportSource.simkl;
    }

    return ImportSource.generic;
  }

  static List safeList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is int) {
      if (value > 1000000000 && value < 2000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
      }
      return null;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static Map<String, dynamic>? asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static int? tmdbId(Map<String, dynamic>? media) {
    if (media == null) return null;

    final direct = media['tmdb_id'] ?? media['tmdb'];

    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct);

    final ids = media['ids'];

    if (ids is Map) {
      final tmdb = ids['tmdb'] ?? ids['tmdb_id'];

      if (tmdb is num) return tmdb.toInt();
      if (tmdb is String) return int.tryParse(tmdb);
    }

    return null;
  }

  static List<String> splitCsvRow(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var quoted = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];

      if (ch == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        out.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }

    out.add(buf.toString());
    return out;
  }
}
