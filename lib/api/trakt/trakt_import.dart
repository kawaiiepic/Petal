import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/trakt/library_api.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/trakt/enum/media_type.dart';

class TraktImportReport {
  int moviesWatched = 0;
  int episodesWatched = 0;
  int watchlisted = 0;
  int rated = 0;
  int skipped = 0;

  String get summary =>
      'Imported $moviesWatched movies watched, $episodesWatched episodes watched, $watchlisted watchlist, $rated ratings. Skipped $skipped.';
}

class TraktImport {
  static Future<TraktImportReport> importFile({required String name, required Uint8List bytes}) async {
    final report = TraktImportReport();
    final lower = name.toLowerCase();
    if (lower.endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (file.isFile && file.name.toLowerCase().endsWith('.json')) {
          await _importJson(file.name, utf8.decode(file.content as List<int>), report);
        }
      }
    } else {
      await _importJson(name, utf8.decode(bytes), report);
    }
    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    await UserLibrary.load();
    return report;
  }

  static Future<void> _importJson(String name, String raw, TraktImportReport report) async {
    final decoded = jsonDecode(raw);
    final items = decoded is List ? decoded : decoded is Map && decoded['items'] is List ? decoded['items'] as List : const [];
    final hint = name.toLowerCase();
    final forceWatchlist = hint.contains('watchlist');
    final forceRating = hint.contains('rating');
    final forceWatched = hint.contains('history') || hint.contains('watched');

    for (final rawItem in items) {
      if (rawItem is! Map) {
        report.skipped++;
        continue;
      }
      final item = Map<String, dynamic>.from(rawItem);
      try {
        await _importItem(item, report, forceWatchlist: forceWatchlist, forceRating: forceRating, forceWatched: forceWatched);
      } catch (_) {
        report.skipped++;
      }
    }
  }

  static Future<void> _importItem(
    Map<String, dynamic> item,
    TraktImportReport report, {
    required bool forceWatchlist,
    required bool forceRating,
    required bool forceWatched,
  }) async {
    final type = (item['type'] as String?) ?? (item['movie'] != null ? 'movie' : item['episode'] != null ? 'episode' : item['show'] != null ? 'show' : '');
    final movie = item['movie'] is Map ? Map<String, dynamic>.from(item['movie'] as Map) : null;
    final show = item['show'] is Map ? Map<String, dynamic>.from(item['show'] as Map) : null;
    final episode = item['episode'] is Map ? Map<String, dynamic>.from(item['episode'] as Map) : null;
    final ratingValue = (item['rating'] as num?)?.toInt();

    final movieTmdb = _tmdbId(movie);
    final showTmdb = _tmdbId(show);

    final treatWatched = forceWatched || item.containsKey('watched_at') || item.containsKey('last_watched_at') || item.containsKey('plays');
    final treatWatchlist = forceWatchlist || item.containsKey('listed_at');
    final treatRating = forceRating || ratingValue != null;

    if (type == 'movie' || movie != null) {
      if (movieTmdb == null) {
        report.skipped++;
        return;
      }
      if (treatWatched) {
        await BackendApi.setProgress(movieTmdb, MediaType.movie, 1.0);
        report.moviesWatched++;
      }
      if (treatWatchlist) {
        await LibraryApi.upsert(tmdbId: movieTmdb, mediaType: MediaType.movie, watchlisted: true);
        report.watchlisted++;
      }
      if (treatRating && ratingValue != null) {
        await LibraryApi.upsert(tmdbId: movieTmdb, mediaType: MediaType.movie, rating: _rating(ratingValue).name);
        report.rated++;
      }
      return;
    }

    if (showTmdb == null) {
      report.skipped++;
      return;
    }

    if (treatWatchlist && (type == 'show' || type == 'episode' || show != null)) {
      await LibraryApi.upsert(tmdbId: showTmdb, mediaType: MediaType.show, watchlisted: true);
      report.watchlisted++;
    }
    if (treatRating && ratingValue != null && (type == 'show' || type == 'movie' || type == 'episode')) {
      await LibraryApi.upsert(tmdbId: showTmdb, mediaType: MediaType.show, rating: _rating(ratingValue).name);
      report.rated++;
    }

    if (!treatWatched) return;

    if (type == 'episode' && episode != null) {
      final season = (episode['season'] as num?)?.toInt() ?? (item['season'] as num?)?.toInt();
      final number = (episode['number'] as num?)?.toInt() ?? (item['number'] as num?)?.toInt();
      if (season == null || number == null) {
        report.skipped++;
        return;
      }
      await BackendApi.setProgress(showTmdb, MediaType.show, 1.0, season: season, episode: number);
      report.episodesWatched++;
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
      final episodes = season['episodes'] as List? ?? const [];
      for (final rawEpisode in episodes) {
        if (rawEpisode is! Map) continue;
        final ep = Map<String, dynamic>.from(rawEpisode);
        final episodeNumber = (ep['number'] as num?)?.toInt();
        if (episodeNumber == null) continue;
        await BackendApi.setProgress(showTmdb, MediaType.show, 1.0, season: seasonNumber, episode: episodeNumber);
        report.episodesWatched++;
      }
    }
  }

  static int? _tmdbId(Map<String, dynamic>? media) {
    final ids = media?['ids'];
    if (ids is! Map) return null;
    final tmdb = ids['tmdb'];
    if (tmdb is num) return tmdb.toInt();
    if (tmdb is String) return int.tryParse(tmdb);
    return null;
  }

  static TitleRating _rating(int value) {
    if (value >= 8) return TitleRating.love;
    return TitleRating.like;
  }
}
