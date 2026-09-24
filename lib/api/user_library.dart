import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/trakt/library_api.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum TitleRating { none, like, love }

class LibraryTitle {
  final int tmdbId;
  final MediaType type;
  final TitleRating rating;
  final bool watchlisted;

  const LibraryTitle({required this.tmdbId, required this.type, this.rating = TitleRating.none, this.watchlisted = false});
}

class UserLibrary {
  static final ValueNotifier<Set<String>> watchlist = ValueNotifier(<String>{});
  static final ValueNotifier<Map<String, TitleRating>> ratings = ValueNotifier(<String, TitleRating>{});
  static bool _listening = false;

  static String _id(int tmdbId, MediaType type) => '${type.name}:$tmdbId';

  static LibraryTitle? parseKey(String key, {TitleRating rating = TitleRating.none, bool watchlisted = false}) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final id = int.tryParse(parts[1]);
    if (id == null) return null;
    final type = parts[0] == 'show' ? MediaType.show : MediaType.movie;
    return LibraryTitle(tmdbId: id, type: type, rating: rating, watchlisted: watchlisted);
  }

  static List<LibraryTitle> watchlistTitles() {
    return watchlist.value.map((key) => parseKey(key, watchlisted: true)).whereType<LibraryTitle>().toList();
  }

  static List<LibraryTitle> ratedTitles() {
    return ratings.value.entries
        .where((e) => e.value != TitleRating.none)
        .map((e) => parseKey(e.key, rating: e.value))
        .whereType<LibraryTitle>()
        .toList();
  }

  static Future<void> load() async {
    if (!_listening) {
      _listening = true;
      BackendApi.authState.addListener(() {
        load();
      });
    }

    try {
      final rows = await LibraryApi.fetch();
      final nextWatchlist = <String>{};
      final nextRatings = <String, TitleRating>{};
      for (final row in rows) {
        final type = row['media_type'] == 'show' ? MediaType.show : MediaType.movie;
        final tmdbId = (row['tmdb_id'] as num).toInt();
        final key = _id(tmdbId, type);
        if (row['watchlisted'] == true) nextWatchlist.add(key);
        final ratingName = row['rating'] as String? ?? 'none';
        final rating = TitleRating.values.firstWhere((v) => v.name == ratingName, orElse: () => TitleRating.none);
        if (rating != TitleRating.none) nextRatings[key] = rating;
      }
      watchlist.value = nextWatchlist;
      ratings.value = nextRatings;
    } catch (_) {
      watchlist.value = {};
      ratings.value = {};
    }
  }

  static bool isInWatchlist(int tmdbId, MediaType type) => watchlist.value.contains(_id(tmdbId, type));

  static TitleRating ratingFor(int tmdbId, MediaType type) => ratings.value[_id(tmdbId, type)] ?? TitleRating.none;

  static bool isWatched(int tmdbId, MediaType type) {
    for (final item in BackendCache.watchHistory.value) {
      if (item.tmdbId != tmdbId) continue;
      if (type == MediaType.movie && item.mediaType == MediaType.movie) {
        return item.completion >= 1;
      }
      if (type == MediaType.show && item.mediaType == MediaType.show) {
        return item.episodes.isNotEmpty && item.episodes.every((e) => e.completion >= 1);
      }
    }
    return false;
  }

  static Future<void> toggleWatchlist(int tmdbId, MediaType type, {String? name}) async {
    final key = _id(tmdbId, type);
    final next = {...watchlist.value};
    final adding = !next.contains(key);
    if (adding) {
      next.add(key);
    } else {
      next.remove(key);
    }
    watchlist.value = next;
    try {
      await LibraryApi.upsert(tmdbId: tmdbId, mediaType: type, watchlisted: adding);
    } catch (_) {
      await load();
    }
    Misc.sendNotification(Text(adding ? 'Watchlist' : 'Removed'), Text(adding ? 'Saved${name != null ? ' $name' : ''}.' : 'Taken off your watchlist.'));
  }

  static Future<void> cycleRating(int tmdbId, MediaType type) async {
    final key = _id(tmdbId, type);
    final current = ratings.value[key] ?? TitleRating.none;
    final nextRating = switch (current) {
      TitleRating.none => TitleRating.like,
      TitleRating.like => TitleRating.love,
      TitleRating.love => TitleRating.none,
    };
    ratings.value = {...ratings.value, key: nextRating};
    try {
      await LibraryApi.upsert(tmdbId: tmdbId, mediaType: type, rating: nextRating.name);
    } catch (_) {
      await load();
    }
    final label = switch (nextRating) {
      TitleRating.like => 'Liked',
      TitleRating.love => 'Loved',
      TitleRating.none => 'Rating cleared',
    };
    Misc.sendNotification(const Text('Rating'), Text(label));
  }

  static Future<void> toggleWatched(int tmdbId, MediaType type, {TmdbShow? show}) async {
    final watched = isWatched(tmdbId, type);
    final target = watched ? 0.0 : 1.0;

    if (type == MediaType.movie) {
      await BackendApi.setProgress(tmdbId, MediaType.movie, target);
    } else {
      final resolved = show ?? await TMDB.tvShow(tmdbId);
      final seasons = resolved.mainSeasons.isNotEmpty ? resolved.mainSeasons : resolved.seasons.where((s) => s.seasonNumber > 0).toList();
      final jobs = <Future<void>>[];
      for (final season in seasons) {
        final count = season.episodeCount <= 0 ? 1 : season.episodeCount;
        for (var episode = 1; episode <= count; episode++) {
          jobs.add(BackendApi.setProgress(tmdbId, MediaType.show, target, season: season.seasonNumber, episode: episode));
        }
      }
      if (jobs.isEmpty) {
        await BackendApi.setProgress(tmdbId, MediaType.show, target, season: 1, episode: 1);
      } else {
        for (var i = 0; i < jobs.length; i += 8) {
          await Future.wait(jobs.sublist(i, i + 8 > jobs.length ? jobs.length : i + 8));
        }
      }
    }

    await BackendCache.fetchWatchHistory();
    await BackendCache.fetchContinueWatching();
    Misc.sendNotification(const Text('Library'), Text(target >= 1 ? 'Marked as watched.' : 'Marked as unwatched.'));
  }
}
