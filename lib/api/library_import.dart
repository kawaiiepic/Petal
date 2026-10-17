
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/trakt/library_api.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

enum ImportSource { auto, trakt, letterboxd, simkl, generic }

typedef ImportProgressCallback = void Function(
  int processed,
  int? total,
);

class LibraryImportReport {
  int moviesWatched = 0;
  int episodesWatched = 0;
  int watchlisted = 0;
  int rated = 0;
  int skipped = 0;
  int existing = 0;
  String source = 'auto';

  String get summary =>
      '[$source] Added $moviesWatched movies, '
      '$episodesWatched episodes, $watchlisted watchlist, '
      '$rated ratings. Already present $existing. '
      'Skipped $skipped.';
}

class _ImportFile {
  const _ImportFile({
    required this.name,
    required this.bytes,
    required this.count,
  });

  final String name;
  final Uint8List bytes;
  final int count;
}

class LibraryImport {
  static const int _concurrency = 4;

  static final Set<int> _watchedMovies = {};
  static final Set<String> _watchedEpisodes = {};
  static final Set<String> _inFlight = {};

  static String _episodeKey(int tmdbId, int season, int episode) =>
      '$tmdbId:$season:$episode';

  static void _buildWatchedIndexes() {
    _watchedMovies.clear();
    _watchedEpisodes.clear();

    for (final item in BackendCache.watchHistory.value) {
      if (item.completion <= 0) continue;

      if (item.mediaType == MediaType.movie) {
        _watchedMovies.add(item.tmdbId);
      } else if (item.mediaType == MediaType.show) {
        for (final ep in item.episodes) {
          if (ep.completion > 0) {
            _watchedEpisodes.add(
              _episodeKey(item.tmdbId, ep.season, ep.episode),
            );
          }
        }
      }
    }
  }

  static Future<void> _processConcurrently<T>(
    List<T> items, {
    required Future<void> Function(T item) process,
    required ImportProgressCallback? onProgress,
  }) async {
    final total = items.length;
    var next = 0;
    var completed = 0;

    onProgress?.call(0, total);

    Future<void> worker() async {
      while (true) {
        // No await between checking and claiming an index.
        if (next >= total) return;
        final index = next++;

        try {
          await process(items[index]);
        } catch (_) {
          // Continue importing other records.
        } finally {
          completed++;
          onProgress?.call(completed, total);
        }
      }
    }

    final workers = total < _concurrency ? total : _concurrency;

    await Future.wait(
      List.generate(workers, (_) => worker()),
    );
  }

  static Future<LibraryImportReport> importFile({
    required String name,
    required Uint8List bytes,
    ImportSource source = ImportSource.auto,
    ImportProgressCallback? onProgress,
  }) async {
    await BackendCache.fetchWatchHistory();
    await UserLibrary.load();

    _watchedMovies.clear();
    _watchedEpisodes.clear();
    _inFlight.clear();
    _buildWatchedIndexes();

    final report = LibraryImportReport();
    final lower = name.toLowerCase();

    final detected =
        source == ImportSource.auto ? _detect(lower, bytes) : source;

    report.source = detected.name;

    if (lower.endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(bytes);

      final relevantFiles = archive.files.where((file) {
        if (!file.isFile) return false;
        return !_shouldSkipFile(file.name.toLowerCase());
      }).toList();

      final files = <_ImportFile>[];

      // Count records first so progress stays cumulative across ZIP files.
      for (final file in relevantFiles) {
        final fileBytes = Uint8List.fromList(
          file.content as List<int>,
        );

        files.add(
          _ImportFile(
            name: file.name,
            bytes: fileBytes,
            count: _countItems(
              file.name,
              fileBytes,
              detected,
            ),
          ),
        );
      }

      final total = files.fold<int>(
        0,
        (sum, file) => sum + file.count,
      );

      var offset = 0;
      onProgress?.call(0, total);

      for (final file in files) {
        await _importNamed(
          file.name,
          file.bytes,
          detected,
          report,
          onProgress: (processed, _) {
            onProgress?.call(offset + processed, total);
          },
        );

        offset += file.count;
        onProgress?.call(offset, total);
      }
    } else {
      final total = _countItems(name, bytes, detected);

      onProgress?.call(0, total);

      await _importNamed(
        name,
        bytes,
        detected,
        report,
        onProgress: onProgress,
      );
    }

    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    await UserLibrary.load();

    // Refresh indexes for any later import in this process.
    _buildWatchedIndexes();

    return report;
  }

  static int _countItems(
    String name,
    Uint8List bytes,
    ImportSource source,
  ) {
    final lower = name.toLowerCase();

    if (_shouldSkipFile(lower)) return 0;

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
        ..._safeList(decoded['movies']),
        ..._safeList(decoded['shows']),
        ..._safeList(decoded['watchlist']),
        ..._safeList(decoded['history']),
        ..._safeList(decoded['ratings']),
      ].length;
    }

    return 0;
  }

  static bool _shouldSkipFile(String lowerName) {
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

  static ImportSource _detect(String name, Uint8List bytes) {
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

  static Future<void> _importNamed(
    String name,
    Uint8List bytes,
    ImportSource source,
    LibraryImportReport report, {
    ImportProgressCallback? onProgress,
  }) async {
    final lower = name.toLowerCase();

    if (_shouldSkipFile(lower)) return;

    if (lower.endsWith('.csv') || source == ImportSource.letterboxd) {
      await _importCsv(
        name,
        utf8.decode(bytes),
        report,
        onProgress: onProgress,
      );
      return;
    }

    final decoded = jsonDecode(utf8.decode(bytes));

    if (source == ImportSource.simkl) {
      await _importSimkl(
        decoded,
        report,
        onProgress: onProgress,
      );
      return;
    }

    await _importJsonList(
      name,
      decoded,
      report,
      onProgress: onProgress,
    );
  }

  static List _safeList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is int) {
      if (value > 1000000000 && value < 2000000000) {
        return DateTime.fromMillisecondsSinceEpoch(
          value * 1000,
          isUtc: true,
        );
      }
      return null;
    }

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static Future<void> _importJsonList(
    String name,
    dynamic decoded,
    LibraryImportReport report, {
    ImportProgressCallback? onProgress,
  }) async {
    final items = decoded is List
        ? decoded
        : decoded is Map && decoded['items'] is List
            ? decoded['items'] as List
            : decoded is Map
                ? [
                    ..._safeList(decoded['movies']),
                    ..._safeList(decoded['shows']),
                    ..._safeList(decoded['watchlist']),
                    ..._safeList(decoded['history']),
                    ..._safeList(decoded['ratings']),
                  ]
                : const [];

    final hint = name.toLowerCase();

    await _processConcurrently(
      items,
      onProgress: onProgress,
      process: (rawItem) async {
        if (rawItem is! Map) {
          report.skipped++;
          return;
        }

        try {
          await _importMap(
            Map<String, dynamic>.from(rawItem),
            report,
            forceWatchlist: hint.contains('watchlist'),
            forceRating: hint.contains('rating'),
            forceWatched:
                hint.contains('history') || hint.contains('watched'),
          );
        } catch (_) {
          report.skipped++;
        }
      },
    );
  }

  static Future<void> _importSimkl(
    dynamic decoded,
    LibraryImportReport report, {
    ImportProgressCallback? onProgress,
  }) async {
    if (decoded is! Map) {
      await _importJsonList(
        'simkl.json',
        decoded,
        report,
        onProgress: onProgress,
      );
      return;
    }

    final movies = decoded['movies'] is List
        ? decoded['movies'] as List
        : const [];

    final shows = decoded['shows'] is List
        ? decoded['shows'] as List
        : decoded['tv'] is List
            ? decoded['tv'] as List
            : const [];

    final items = [...movies, ...shows];

    await _processConcurrently(
      items,
      onProgress: onProgress,
      process: (raw) async {
        if (raw is! Map) {
          report.skipped++;
          return;
        }

        try {
          final item = Map<String, dynamic>.from(raw);

          final status =
              (item['status'] as String? ??
                      item['list'] as String? ??
                      '')
                  .toLowerCase();

          await _importMap(
            item,
            report,
            forceWatchlist: status.contains('plantowatch') ||
                status.contains('watchlist'),
            forceRating:
                item['user_rating'] != null || item['rating'] != null,
            forceWatched: status.contains('complete') ||
                status.contains('watched') ||
                item['last_watched'] != null,
          );
        } catch (_) {
          report.skipped++;
        }
      },
    );
  }

  static Future<void> _importCsv(
    String name,
    String raw,
    LibraryImportReport report, {
    ImportProgressCallback? onProgress,
  }) async {
    final lines = const LineSplitter()
        .convert(raw)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) return;

    final headers = _splitCsv(lines.first)
        .map((header) => header.trim().toLowerCase())
        .toList();

    final hint = name.toLowerCase();

    final watchlistFile = hint.contains('watchlist') ||
        (headers.contains('listed date') &&
            !headers.contains('watched date'));

    final ratingFile =
        hint.contains('rating') || headers.contains('rating');

    final watchedFile =
        hint.contains('watched') || headers.contains('watched date');

    final rows = lines.skip(1).toList();

    await _processConcurrently(
      rows,
      onProgress: onProgress,
      process: (line) async {
        try {
          final cols = _splitCsv(line);

          if (cols.isEmpty) return;

          String cell(String key) {
            final index = headers.indexOf(key);
            return index >= 0 && index < cols.length
                ? cols[index].trim()
                : '';
          }

          final title =
              cell('name').isNotEmpty ? cell('name') : cell('title');

          final year = int.tryParse(cell('year'));
          final ratingRaw = cell('rating');

          final tmdbCell =
              cell('tmdb') + cell('tmdb id') + cell('tmdb_id');

          var tmdbId = int.tryParse(tmdbCell);

          tmdbId ??= await _searchTitle(
            title,
            year: year,
            movie: true,
          );

          if (tmdbId == null) {
            report.skipped++;
            return;
          }

          final watchedAt = _parseDate(
            [
              cell('watched date'),
              cell('watched_at'),
              cell('date'),
            ].firstWhere(
              (value) => value.isNotEmpty,
              orElse: () => '',
            ),
          );

          if (watchedFile || cell('watched date').isNotEmpty) {
            await _markWatched(
              tmdbId,
              MediaType.movie,
              report,
              watchedAt: watchedAt,
            );
          }

          if (watchlistFile) {
            await _markWatchlist(
              tmdbId,
              MediaType.movie,
              report,
            );
          }

          if (ratingFile && ratingRaw.isNotEmpty) {
            final value = double.tryParse(ratingRaw);

            if (value != null) {
              final scaled =
                  value <= 5 ? (value * 2).round() : value.round();

              await _markRating(
                tmdbId,
                MediaType.movie,
                scaled,
                report,
              );
            }
          }
        } catch (_) {
          report.skipped++;
        }
      },
    );
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

    final ratingValue = (item['rating'] as num?)?.toInt() ??
        (item['user_rating'] as num?)?.toInt();

    final watchedAt =
        _parseDate(item['watched_at'] ?? item['last_watched_at']);

    var movieTmdb = _tmdbId(movie) ?? _tmdbId(item);
    var showTmdb = _tmdbId(show);

    if (type == 'movie' && movieTmdb == null) {
      movieTmdb = await _searchTitle(
        item['title'] as String? ?? movie?['title'] as String?,
        year: item['year'] as int?,
        movie: true,
      );
    }

    if ((type == 'show' || type == 'episode') && showTmdb == null) {
      showTmdb = await _searchTitle(
        show?['title'] as String? ?? item['title'] as String?,
        year: item['year'] as int?,
        movie: false,
      );
    }

    final treatWatched = forceWatched ||
        item.containsKey('watched_at') ||
        item.containsKey('last_watched_at') ||
        item.containsKey('plays');

    final treatWatchlist =
        forceWatchlist || item.containsKey('listed_at');

    final treatRating = forceRating || ratingValue != null;

    if (type == 'movie' ||
        movie != null ||
        (movieTmdb != null && type != 'show' && type != 'episode')) {
      if (movieTmdb == null) {
        report.skipped++;
        return;
      }

      if (treatWatched) {
        await _markWatched(
          movieTmdb,
          MediaType.movie,
          report,
          watchedAt: watchedAt,
        );
      }

      if (treatWatchlist) {
        await _markWatchlist(
          movieTmdb,
          MediaType.movie,
          report,
        );
      }

      if (treatRating && ratingValue != null) {
        await _markRating(
          movieTmdb,
          MediaType.movie,
          ratingValue,
          report,
        );
      }

      return;
    }

    if (showTmdb == null) {
      report.skipped++;
      return;
    }

    if (treatWatchlist) {
      await _markWatchlist(showTmdb, MediaType.show, report);
    }

    if (treatRating && ratingValue != null) {
      await _markRating(
        showTmdb,
        MediaType.show,
        ratingValue,
        report,
      );
    }

    if (!treatWatched) return;

    if (type == 'episode' && episode != null) {
      final season = (episode['season'] as num?)?.toInt() ??
          (item['season'] as num?)?.toInt();

      final number = (episode['number'] as num?)?.toInt() ??
          (item['number'] as num?)?.toInt();

      if (season == null || number == null) {
        report.skipped++;
        return;
      }

      await _markEpisode(
        showTmdb,
        season,
        number,
        report,
        watchedAt: watchedAt,
      );

      return;
    }

    final seasons = _safeList(item['seasons']);

    if (seasons.isEmpty) return;

    for (final rawSeason in seasons) {
      if (rawSeason is! Map) continue;

      final season = Map<String, dynamic>.from(rawSeason);
      final seasonNumber = (season['number'] as num?)?.toInt();

      if (seasonNumber == null || seasonNumber <= 0) continue;

      for (final rawEpisode in _safeList(season['episodes'])) {
        if (rawEpisode is! Map) continue;

        final episodeNumber =
            (rawEpisode['number'] as num?)?.toInt();

        if (episodeNumber == null) continue;

        final epWatchedAt = _parseDate(
              rawEpisode['last_watched_at'] ??
                  rawEpisode['watched_at'],
            ) ??
            watchedAt;

        await _markEpisode(
          showTmdb,
          seasonNumber,
          episodeNumber,
          report,
          watchedAt: epWatchedAt,
        );
      }
    }
  }

  static Future<void> _markWatched(
    int tmdbId,
    MediaType type,
    LibraryImportReport report, {
    DateTime? watchedAt,
  }) async {
    final key = 'movie:$tmdbId';

    if (_movieWatched(tmdbId) || !_inFlight.add(key)) {
      report.existing++;
      return;
    }

    try {
      await BackendApi.setProgress(
        tmdbId,
        type,
        1.0,
        watchedAt: watchedAt,
      );

      _watchedMovies.add(tmdbId);
      report.moviesWatched++;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<void> _markEpisode(
    int tmdbId,
    int season,
    int episode,
    LibraryImportReport report, {
    DateTime? watchedAt,
  }) async {
    final key = _episodeKey(tmdbId, season, episode);
    final reservation = 'episode:$key';

    if (_episodeWatched(tmdbId, season, episode) ||
        !_inFlight.add(reservation)) {
      report.existing++;
      return;
    }

    try {
      await BackendApi.setProgress(
        tmdbId,
        MediaType.show,
        1.0,
        season: season,
        episode: episode,
        watchedAt: watchedAt,
      );

      _watchedEpisodes.add(key);
      report.episodesWatched++;
    } finally {
      _inFlight.remove(reservation);
    }
  }

  static Future<void> _markWatchlist(
    int tmdbId,
    MediaType type,
    LibraryImportReport report,
  ) async {
    final key = 'watchlist:${type.name}:$tmdbId';

    if (UserLibrary.isInWatchlist(tmdbId, type) ||
        !_inFlight.add(key)) {
      report.existing++;
      return;
    }

    try {
      await LibraryApi.upsert(
        tmdbId: tmdbId,
        mediaType: type,
        watchlisted: true,
        merge: true,
      );

      UserLibrary.watchlist.value = {
        ...UserLibrary.watchlist.value,
        '${type.name}:$tmdbId',
      };

      report.watchlisted++;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<void> _markRating(
    int tmdbId,
    MediaType type,
    int value,
    LibraryImportReport report,
  ) async {
    final key = 'rating:${type.name}:$tmdbId';

    if (UserLibrary.ratingFor(tmdbId, type) != TitleRating.none ||
        !_inFlight.add(key)) {
      report.existing++;
      return;
    }

    try {
      final rating = value >= 8 ? TitleRating.love : TitleRating.like;

      await LibraryApi.upsert(
        tmdbId: tmdbId,
        mediaType: type,
        rating: rating.name,
        merge: true,
      );

      UserLibrary.ratings.value = {
        ...UserLibrary.ratings.value,
        '${type.name}:$tmdbId': rating,
      };

      report.rated++;
    } finally {
      _inFlight.remove(key);
    }
  }

  static bool _movieWatched(int tmdbId) =>
      _watchedMovies.contains(tmdbId);

  static bool _episodeWatched(
    int tmdbId,
    int season,
    int episode,
  ) =>
      _watchedEpisodes.contains(
        _episodeKey(tmdbId, season, episode),
      );

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

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

  static Future<int?> _searchTitle(
    String? title, {
    int? year,
    required bool movie,
  }) async {
    if (title == null || title.trim().isEmpty) return null;

    final kind = movie ? 'movie' : 'tv';

    final yearKey = year == null
        ? ''
        : (movie
            ? '&year=$year'
            : '&first_air_date_year=$year');

    final response = await TMDB.tmdbApi(
      '/search/$kind?query=${Uri.encodeQueryComponent(title)}$yearKey',
    );

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
