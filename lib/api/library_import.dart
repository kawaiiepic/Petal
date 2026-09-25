import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/trakt/library_api.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

enum ImportSource { auto, trakt, letterboxd, simkl, generic }

class LibraryImportReport {
  int moviesWatched = 0;
  int episodesWatched = 0;
  int watchlisted = 0;
  int rated = 0;
  int skipped = 0;
  int existing = 0;
  String source = 'auto';

  String get summary =>
      '[$source] Added $moviesWatched movies, $episodesWatched episodes, $watchlisted watchlist, $rated ratings. Already present $existing. Skipped $skipped.';
}

class LibraryImport {
  static Future<LibraryImportReport> importFile({
    required String name,
    required Uint8List bytes,
    ImportSource source = ImportSource.auto,
  }) async {
    await BackendCache.fetchWatchHistory();
    await UserLibrary.load();

    final report = LibraryImportReport();
    final lower = name.toLowerCase();
    final detected = source == ImportSource.auto ? _detect(lower, bytes) : source;
    report.source = detected.name;

    if (lower.endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile) {
          await _importNamed(file.name, Uint8List.fromList(file.content as List<int>), detected, report);
        }
      }
    } else {
      await _importNamed(name, bytes, detected, report);
    }

    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    await UserLibrary.load();
    return report;
  }

  static ImportSource _detect(String name, Uint8List bytes) {
    if (name.contains('letterboxd') || name.endsWith('.csv')) return ImportSource.letterboxd;
    if (name.contains('simkl')) return ImportSource.simkl;
    if (name.contains('trakt') || name.contains('history') || name.contains('watched') || name.contains('watchlist') || name.contains('rating')) {
      return ImportSource.trakt;
    }
    final head = utf8.decode(bytes.take(200).toList(), allowMalformed: true).toLowerCase();
    if (head.contains('letterboxd') || head.contains('watched date')) return ImportSource.letterboxd;
    if (head.contains('"simkl"') || head.contains('simkl_id')) return ImportSource.simkl;
    return ImportSource.generic;
  }

  static Future<void> _importNamed(String name, Uint8List bytes, ImportSource source, LibraryImportReport report) async {
    final lower = name.toLowerCase();
    if (lower.endsWith('.csv') || source == ImportSource.letterboxd) {
      await _importCsv(name, utf8.decode(bytes), report);
      return;
    }
    final raw = utf8.decode(bytes);
    final decoded = jsonDecode(raw);
    if (source == ImportSource.simkl) {
      await _importSimkl(decoded, report);
      return;
    }
    await _importJsonList(name, decoded, report);
  }

  static Future<void> _importJsonList(String name, dynamic decoded, LibraryImportReport report) async {
    final items = decoded is List
        ? decoded
        : decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : decoded is Map
        ? [
            ...((decoded['movies'] as List?) ?? const []),
            ...((decoded['shows'] as List?) ?? const []),
            ...((decoded['watchlist'] as List?) ?? const []),
            ...((decoded['history'] as List?) ?? const []),
            ...((decoded['ratings'] as List?) ?? const []),
          ]
        : const [];
    final hint = name.toLowerCase();
    for (final rawItem in items) {
      if (rawItem is! Map) {
        report.skipped++;
        continue;
      }
      try {
        await _importMap(
          Map<String, dynamic>.from(rawItem),
          report,
          forceWatchlist: hint.contains('watchlist'),
          forceRating: hint.contains('rating'),
          forceWatched: hint.contains('history') || hint.contains('watched'),
        );
      } catch (_) {
        report.skipped++;
      }
    }
  }

  static Future<void> _importSimkl(dynamic decoded, LibraryImportReport report) async {
    if (decoded is! Map) {
      await _importJsonList('simkl.json', decoded, report);
      return;
    }
    final movies = decoded['movies'] as List? ?? const [];
    final shows = decoded['shows'] as List? ?? decoded['tv'] as List? ?? const [];
    for (final raw in [...movies, ...shows]) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final status = (item['status'] as String? ?? item['list'] as String? ?? '').toLowerCase();
      await _importMap(
        item,
        report,
        forceWatchlist: status.contains('plantowatch') || status.contains('watchlist'),
        forceRating: item['user_rating'] != null || item['rating'] != null,
        forceWatched: status.contains('complete') || status.contains('watched') || item['last_watched'] != null,
      );
    }
  }

  static Future<void> _importCsv(String name, String raw, LibraryImportReport report) async {
    final lines = const LineSplitter().convert(raw).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    final headers = _splitCsv(lines.first).map((h) => h.trim().toLowerCase()).toList();
    final hint = name.toLowerCase();
    final watchlistFile = hint.contains('watchlist') || headers.contains('listed date') && !headers.contains('watched date');
    final ratingFile = hint.contains('rating') || headers.contains('rating');
    final watchedFile = hint.contains('watched') || headers.contains('watched date');

    for (final line in lines.skip(1)) {
      final cols = _splitCsv(line);
      if (cols.isEmpty) continue;
      String cell(String key) {
        final i = headers.indexOf(key);
        return i >= 0 && i < cols.length ? cols[i].trim() : '';
      }

      final title = cell('name').isNotEmpty ? cell('name') : cell('title');
      final year = int.tryParse(cell('year'));
      final ratingRaw = cell('rating');
      final tmdbCell = cell('tmdb') + cell('tmdb id') + cell('tmdb_id');
      var tmdbId = int.tryParse(tmdbCell);
      tmdbId ??= await _searchTitle(title, year: year, movie: true);
      if (tmdbId == null) {
        report.skipped++;
        continue;
      }

      if (watchedFile || cell('watched date').isNotEmpty) {
        await _markWatched(tmdbId, MediaType.movie, report);
      }
      if (watchlistFile) {
        await _markWatchlist(tmdbId, MediaType.movie, report);
      }
      if (ratingFile && ratingRaw.isNotEmpty) {
        final value = double.tryParse(ratingRaw);
        if (value != null) {
          final scaled = value <= 5 ? (value * 2).round() : value.round();
          await _markRating(tmdbId, MediaType.movie, scaled, report);
        }
      }
    }
  }

  static Future<void> _importMap(
    Map<String, dynamic> item,
    LibraryImportReport report, {
    required bool forceWatchlist,
    required bool forceRating,
    required bool forceWatched,
  }) async {
    final type = (item['type'] as String?) ??
        (item['movie'] != null
            ? 'movie'
            : item['episode'] != null
            ? 'episode'
            : item['show'] != null || item['tv'] != null
            ? 'show'
            : item['tmdb_id'] != null || item['tmdb'] != null
            ? (item['media_type'] as String? ?? 'movie')
            : '');
    final movie = _asMap(item['movie']);
    final show = _asMap(item['show']) ?? _asMap(item['tv']);
    final episode = _asMap(item['episode']);
    final ratingValue = (item['rating'] as num?)?.toInt() ?? (item['user_rating'] as num?)?.toInt();

    var movieTmdb = _tmdbId(movie) ?? _tmdbId(item);
    var showTmdb = _tmdbId(show);
    if (type == 'movie' && movieTmdb == null) {
      movieTmdb = await _searchTitle(item['title'] as String? ?? movie?['title'] as String?, year: item['year'] as int?, movie: true);
    }
    if ((type == 'show' || type == 'episode') && showTmdb == null) {
      showTmdb = await _searchTitle(show?['title'] as String? ?? item['title'] as String?, year: item['year'] as int?, movie: false);
    }

    final treatWatched = forceWatched || item.containsKey('watched_at') || item.containsKey('last_watched_at') || item.containsKey('plays');
    final treatWatchlist = forceWatchlist || item.containsKey('listed_at');
    final treatRating = forceRating || ratingValue != null;

    if (type == 'movie' || movie != null || (movieTmdb != null && type != 'show' && type != 'episode')) {
      if (movieTmdb == null) {
        report.skipped++;
        return;
      }
      if (treatWatched) await _markWatched(movieTmdb, MediaType.movie, report);
      if (treatWatchlist) await _markWatchlist(movieTmdb, MediaType.movie, report);
      if (treatRating && ratingValue != null) await _markRating(movieTmdb, MediaType.movie, ratingValue, report);
      return;
    }

    if (showTmdb == null) {
      report.skipped++;
      return;
    }
    if (treatWatchlist) await _markWatchlist(showTmdb, MediaType.show, report);
    if (treatRating && ratingValue != null) await _markRating(showTmdb, MediaType.show, ratingValue, report);
    if (!treatWatched) return;

    if (type == 'episode' && episode != null) {
      final season = (episode['season'] as num?)?.toInt() ?? (item['season'] as num?)?.toInt();
      final number = (episode['number'] as num?)?.toInt() ?? (item['number'] as num?)?.toInt();
      if (season == null || number == null) {
        report.skipped++;
        return;
      }
      await _markEpisode(showTmdb, season, number, report);
      return;
    }

    final seasons = item['seasons'] as List? ?? const [];
    if (seasons.isEmpty) {
      report.skipped++;
      return;
    }
    for (final rawSeason in seasons) {
      if (rawSeason is! Map) continue;
      final season = Map<String, dynamic>.from(rawSeason);
      final seasonNumber = (season['number'] as num?)?.toInt();
      if (seasonNumber == null || seasonNumber <= 0) continue;
      for (final rawEpisode in season['episodes'] as List? ?? const []) {
        if (rawEpisode is! Map) continue;
        final episodeNumber = (rawEpisode['number'] as num?)?.toInt();
        if (episodeNumber == null) continue;
        await _markEpisode(showTmdb, seasonNumber, episodeNumber, report);
      }
    }
  }

  static Future<void> _markWatched(int tmdbId, MediaType type, LibraryImportReport report) async {
    if (_movieWatched(tmdbId)) {
      report.existing++;
      return;
    }
    await BackendApi.setProgress(tmdbId, type, 1.0);
    report.moviesWatched++;
  }

  static Future<void> _markEpisode(int tmdbId, int season, int episode, LibraryImportReport report) async {
    if (_episodeWatched(tmdbId, season, episode)) {
      report.existing++;
      return;
    }
    await BackendApi.setProgress(tmdbId, MediaType.show, 1.0, season: season, episode: episode);
    report.episodesWatched++;
  }

  static Future<void> _markWatchlist(int tmdbId, MediaType type, LibraryImportReport report) async {
    if (UserLibrary.isInWatchlist(tmdbId, type)) {
      report.existing++;
      return;
    }
    await LibraryApi.upsert(tmdbId: tmdbId, mediaType: type, watchlisted: true, merge: true);
    UserLibrary.watchlist.value = {...UserLibrary.watchlist.value, '${type.name}:$tmdbId'};
    report.watchlisted++;
  }

  static Future<void> _markRating(int tmdbId, MediaType type, int value, LibraryImportReport report) async {
    if (UserLibrary.ratingFor(tmdbId, type) != TitleRating.none) {
      report.existing++;
      return;
    }
    final rating = value >= 8 ? TitleRating.love : TitleRating.like;
    await LibraryApi.upsert(tmdbId: tmdbId, mediaType: type, rating: rating.name, merge: true);
    UserLibrary.ratings.value = {...UserLibrary.ratings.value, '${type.name}:$tmdbId': rating};
    report.rated++;
  }

  static bool _movieWatched(int tmdbId) {
    for (final item in BackendCache.watchHistory.value) {
      if (item.tmdbId == tmdbId && item.mediaType == MediaType.movie && item.completion > 0) return true;
    }
    return false;
  }

  static bool _episodeWatched(int tmdbId, int season, int episode) {
    for (final item in BackendCache.watchHistory.value) {
      if (item.tmdbId != tmdbId || item.mediaType != MediaType.show) continue;
      for (final ep in item.episodes) {
        if (ep.season == season && ep.episode == episode && ep.completion > 0) return true;
      }
    }
    return false;
  }

  static Map<String, dynamic>? _asMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : null;

  static int? _tmdbId(Map<String, dynamic>? media) {
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

  static Future<int?> _searchTitle(String? title, {int? year, required bool movie}) async {
    if (title == null || title.trim().isEmpty) return null;
    final kind = movie ? 'movie' : 'tv';
    final yearKey = year == null ? '' : (movie ? '&year=$year' : '&first_air_date_year=$year');
    final response = await TMDB.tmdbApi('/search/$kind?query=${Uri.encodeQueryComponent(title)}$yearKey');
    final results = response.data['results'] as List? ?? const [];
    if (results.isEmpty) return null;
    return (results.first['id'] as num?)?.toInt();
  }

  static List<String> _splitCsv(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        quoted = !quoted;
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
