import 'dart:async';
import 'package:petal/api/show_watch_writer.dart';
import 'package:petal/api/offline_progress_sync.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/utils/show_watch_plan.dart';
import 'package:petal/utils/frame_safe_value_notifier.dart';
import 'package:petal/api/history_actions.dart';
import 'package:flutter/foundation.dart' show setEquals, mapEquals;
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/backend/library_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UserLibrary {
  static final ValueNotifier<Set<String>> watchlist = ValueNotifier(<String>{});
  static final ValueNotifier<Map<String, TitleRating>> ratings = ValueNotifier(
    <String, TitleRating>{},
  );
  static final pendingWatched = FrameSafeValueNotifier<Map<String, bool>>({});
  static final _watchWrites = <String, Future<void>>{};
  static final _knownPlans = <int, ({DateTime at, List<ShowEpisodeTarget> episodes})>{};

  static String _watchKey(int id, MediaType type) =>
      '${BackendApi.profileCacheKey}|${type.name}:$id';
  static bool isChangingWatched(int id, MediaType type) =>
      pendingWatched.value.containsKey(_watchKey(id, type));
  static double? pendingCompletion(int id, MediaType type) {
    final value = pendingWatched.value[_watchKey(id, type)];
    return value == null ? null : value ? 1.0 : 0.0;
  }

  static bool _listening = false;
  static String? _profileKey;
  static int _revision = 0;

  static String _id(int tmdbId, MediaType type) => '${type.name}:$tmdbId';

  static LibraryTitle? parseKey(
    String key, {
    TitleRating rating = TitleRating.none,
    bool watchlisted = false,
  }) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final id = int.tryParse(parts[1]);
    if (id == null) return null;
    final type = parts[0] == 'show' ? MediaType.show : MediaType.movie;
    return LibraryTitle(
      tmdbId: id,
      type: type,
      rating: rating,
      watchlisted: watchlisted,
    );
  }

  static List<LibraryTitle> watchlistTitles() {
    return watchlist.value
        .map((key) => parseKey(key, watchlisted: true))
        .whereType<LibraryTitle>()
        .toList();
  }

  static List<LibraryTitle> ratedTitles() {
    return ratings.value.entries
        .where((e) => e.value != TitleRating.none)
        .map((e) => parseKey(e.key, rating: e.value))
        .whereType<LibraryTitle>()
        .toList();
  }

  static Future<void> load({bool force = false}) async {
    if (!_listening) {
      _listening = true;
      LibraryApi.updated.addListener(() => load());
      BackendApi.authState.addListener(() {
        load();
      });
    }

    final key = BackendApi.profileCacheKey;
    if (key != _profileKey) {
      _profileKey = key;
      _revision++;
      watchlist.value = {};
      ratings.value = {};
    }
    final pending = LibraryApi.fetch(force: force);
    final revision = _revision;
    final apiRevision = LibraryApi.revision;
    try {
      final rows = await pending;
      if (key != BackendApi.profileCacheKey ||
          revision != _revision ||
          apiRevision != LibraryApi.revision)
        return;
      final nextWatchlist = <String>{};
      final nextRatings = <String, TitleRating>{};
      for (final row in rows) {
        final type = row['media_type'] == 'show'
            ? MediaType.show
            : MediaType.movie;
        final tmdbId = (row['tmdb_id'] as num).toInt();
        final key = _id(tmdbId, type);
        if (row['watchlisted'] == true) nextWatchlist.add(key);
        final ratingName = row['rating'] as String? ?? 'none';
        final rating = TitleRating.values.firstWhere(
          (v) => v.name == ratingName,
          orElse: () => TitleRating.none,
        );
        if (rating != TitleRating.none) nextRatings[key] = rating;
      }
      if (!setEquals(watchlist.value, nextWatchlist))
        watchlist.value = nextWatchlist;
      if (!mapEquals(ratings.value, nextRatings)) ratings.value = nextRatings;
    } catch (_) {
      // Retain already displayed values on a transient failure; the next call retries.
    }
  }

  static bool isInWatchlist(int tmdbId, MediaType type) =>
      watchlist.value.contains(_id(tmdbId, type));

  static TitleRating ratingFor(int tmdbId, MediaType type) =>
      ratings.value[_id(tmdbId, type)] ?? TitleRating.none;

  static bool isWatched(int tmdbId, MediaType type, {int? totalEpisodes}) {
    final pending = pendingCompletion(tmdbId, type);
    if (pending != null) return pending >= 1;
    for (final item in BackendCache.watchHistory.value) {
      if (item.tmdbId != tmdbId) continue;
      if (type == MediaType.movie && item.mediaType == MediaType.movie) {
        return WatchProgress.isWatched(item.completion);
      }
      if (type == MediaType.show && item.mediaType == MediaType.show) {
        final plan = _knownPlans[tmdbId];
        if (plan != null && DateTime.now().difference(plan.at) < const Duration(minutes: 5)) {
          return plan.episodes.isNotEmpty &&
              ShowWatchPlan.missing(plan.episodes, item.episodes, 1).isEmpty;
        }
        final regular = item.episodes.where((e) => e.season > 0).toList();
        return totalEpisodes != null && totalEpisodes > 0 &&
            regular.map((e) => '${e.season}:${e.episode}').toSet().length >= totalEpisodes &&
            regular.every((e) => WatchProgress.isWatched(e.completion));
      }
    }
    return false;
  }

  static Future<void> toggleWatchlist(
    int tmdbId,
    MediaType type, {
    String? name,
  }) async {
    _revision++;
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
      await LibraryApi.upsert(
        tmdbId: tmdbId,
        mediaType: type,
        watchlisted: adding,
      );
    } catch (_) {
      await load(force: true);
    }
    AppNotifications.sendNotification(
      Text(adding ? 'Watchlist' : 'Removed'),
      Text(
        adding
            ? 'Saved${name != null ? ' $name' : ''}.'
            : 'Taken off your watchlist.',
      ),
    );
  }

  static Future<void> cycleRating(int tmdbId, MediaType type) async {
    _revision++;
    final key = _id(tmdbId, type);
    final current = ratings.value[key] ?? TitleRating.none;
    final nextRating = switch (current) {
      TitleRating.none => TitleRating.like,
      TitleRating.like => TitleRating.love,
      TitleRating.love => TitleRating.none,
    };
    ratings.value = {...ratings.value, key: nextRating};
    try {
      await LibraryApi.upsert(
        tmdbId: tmdbId,
        mediaType: type,
        rating: nextRating.name,
      );
    } catch (_) {
      await load(force: true);
    }
    final label = switch (nextRating) {
      TitleRating.like => 'Liked',
      TitleRating.love => 'Loved',
      TitleRating.none => 'Rating cleared',
    };
    AppNotifications.sendNotification(const Text('Rating'), Text(label));
  }

  static Future<void> toggleWatched(
    int tmdbId, MediaType type, {TmdbShow? show, bool? watched},
  ) {
    final profile = BackendApi.profileCacheKey;
    final profileId = BackendApi.authState.selectedProfile?.id;
    if (profile == null || profileId == null) return Future.value();
    final key = _watchKey(tmdbId, type);
    return _watchWrites.putIfAbsent(key, () =>
      _changeWatched(tmdbId, type, profile, profileId, key, show, watched)
        .whenComplete(() => _watchWrites.remove(key)));
  }

  static Future<void> _changeWatched(int id, MediaType type, String profile,
      String profileId, String key, TmdbShow? show, bool? watched) async {
    final target = (watched ?? isWatched(id, type, totalEpisodes: show?.numberOfEpisodes)) ? 0.0 : 1.0;
    pendingWatched.value = {...pendingWatched.value, key: target >= 1};
    final before = BackendCache.watchHistory.value
        .where((h) => h.tmdbId == id && h.mediaType == MediaType.show)
        .firstOrNull;
    var optimistic = false;
    try {
      if (type == MediaType.movie) {
        await HistoryActions.setProgress(id, type, target, refresh: false);
      } else {
        await HistoryActions.exclusive(() async {
          final resolved = show ?? await TMDB.tvShow(id);
          if (profile != BackendApi.profileCacheKey) throw StateError('Profile changed.');
          final plan = await ShowWatchPlan.load(resolved,
            loadSeason: (number) => TMDB.tvSeason(id, number));
          if (plan.isEmpty) throw StateError('No available episodes were found.');
          if (profile != BackendApi.profileCacheKey) throw StateError('Profile changed.');
          _knownPlans[id] = (at: DateTime.now(), episodes: plan);
          BackendCache.invalidateProgress(profileKey: profile);
          BackendCache.optimisticShow(profile, ShowWatchPlan.optimistic(
            id, BackendCache.watchHistory.value, plan, target, DateTime.now()));
          optimistic = true;
          await ShowWatchWriter.save(profile: profile, profileId: profileId,
            id: id, targets: plan, completion: target);
          await OfflineProgressSync.instance.discardTitle(
            profileKey: profile, mediaId: id, isShow: true);
          await DownloadManager.load();
          if (profile != BackendApi.profileCacheKey) throw StateError('Profile changed.');
          final planned = plan.toSet();
          for (final download in DownloadManager.items.value.where((d) =>
              d.tmdbId == id && d.isShow &&
              planned.contains((season: d.season!, episode: d.episode!)))) {
            await DownloadManager.setPlaybackProgress(download.id, target, sync: false);
          }
        });
      }
      BackendCache.invalidateProgress(profileKey: profile);
      BackendCache.finishOptimisticShow(profile, id);
      optimistic = false;
      if (profile == BackendApi.profileCacheKey) {
        // The checked state stays visible while canonical counts/dates refresh.
        unawaited(Future.wait([
          BackendCache.fetchWatchHistory(force: true),
          BackendCache.fetchContinueWatching(force: true),
        ]).then<void>((_) {}).catchError((Object _) {}));
        AppNotifications.sendNotification(const Text('Library'),
          Text(target >= 1 ? 'Marked as watched.' : 'Marked as unwatched.'));
      }
    } catch (error) {
      if (optimistic) BackendCache.finishOptimisticShow(profile, id,
        restore: before, rollback: true);
      BackendCache.invalidateProgress(profileKey: profile);
      if (profile == BackendApi.profileCacheKey) {
        AppNotifications.sendNotification(const Text('Watch status could not be saved'),
          Text(error is StateError ? error.message.toString()
            : 'Some episodes may not have saved. Please retry.'));
        unawaited(BackendCache.fetchWatchHistory(force: true).catchError((Object _) {}));
      }
    } finally {
      final next = {...pendingWatched.value}..remove(key);
      pendingWatched.value = next;
    }
  }
}
