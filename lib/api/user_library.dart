import 'dart:convert';

import 'package:petal/api/misc.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TitleRating { none, like, love }

class UserLibrary {
  static const _watchlistKey = 'user_watchlist';
  static const _ratingsKey = 'user_ratings';

  static final ValueNotifier<Set<String>> watchlist = ValueNotifier(<String>{});
  static final ValueNotifier<Map<String, TitleRating>> ratings = ValueNotifier(<String, TitleRating>{});

  static String _id(int tmdbId, MediaType type) => '${type.name}:$tmdbId';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    watchlist.value = {...(prefs.getStringList(_watchlistKey) ?? const <String>[])};
    final raw = prefs.getString(_ratingsKey);
    if (raw == null || raw.isEmpty) {
      ratings.value = {};
      return;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    ratings.value = {
      for (final entry in decoded.entries) entry.key: TitleRating.values.firstWhere((v) => v.name == entry.value, orElse: () => TitleRating.none),
    };
  }

  static Future<void> _persistWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_watchlistKey, watchlist.value.toList());
  }

  static Future<void> _persistRatings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ratingsKey, jsonEncode({for (final e in ratings.value.entries) e.key: e.value.name}));
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
    await _persistWatchlist();
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
    await _persistRatings();
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
      await BackendApi.setProgress(tmdbId, MediaType.movie, target, notify: false);
    } else {
      final resolved = show ?? await TMDB.tvShow(tmdbId);
      final seasons = resolved.mainSeasons.isNotEmpty ? resolved.mainSeasons : resolved.seasons.where((s) => s.seasonNumber > 0).toList();
      final jobs = <Future<void>>[];
      for (final season in seasons) {
        final count = season.episodeCount <= 0 ? 1 : season.episodeCount;
        for (var episode = 1; episode <= count; episode++) {
          jobs.add(BackendApi.setProgress(tmdbId, MediaType.show, target, season: season.seasonNumber, episode: episode, notify: false));
        }
      }
      if (jobs.isEmpty) {
        await BackendApi.setProgress(tmdbId, MediaType.show, target, season: 1, episode: 1, notify: false);
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
