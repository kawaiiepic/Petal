import 'package:petal/api/api.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/upcoming_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class UpcomingReleases {
  static final ValueNotifier<List<UpcomingItem>> items = ValueNotifier(
    const [],
  );
  static Future<void>? _inFlight;
  static String? _profileKey;

  static Future<void> fetch() {
    final key = BackendApi.profileCacheKey;
    if (_profileKey != key) {
      _profileKey = key;
      _inFlight = null;
      items.value = const [];
    }
    if (key == null) return Future.value();
    if (_inFlight != null) return _inFlight!;
    late final Future<void> request;
    request = _load(key).whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
    return _inFlight = request;
  }

  static Future<void> _load(String profileKey) async {
    await BackendCache.fetchWatchHistory();
    if (profileKey != BackendApi.profileCacheKey) return;
    final ids = <int>{};
    for (final item in BackendCache.watchHistory.value) {
      if (item.mediaType == MediaType.show) ids.add(item.tmdbId);
    }
    for (final title in UserLibrary.watchlistTitles()) {
      if (title.type == MediaType.show) ids.add(title.tmdbId);
    }
    if (ids.isEmpty &&
        !UserLibrary.watchlistTitles().any(
          (title) => title.type == MediaType.movie,
        )) {
      items.value = const [];
      return;
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final cutoff = today.add(const Duration(days: 45));
    final found = <UpcomingItem>[];

    await Future.wait(
      ids.take(30).map((id) async {
        try {
          final response = await TMDB.tmdbApi('/tv/$id');
          final data = response.data as Map<String, dynamic>;
          final next = data['next_episode_to_air'] as Map<String, dynamic>?;
          final last = data['last_episode_to_air'] as Map<String, dynamic>?;
          final seasonNumber =
              (next?['season_number'] as num?)?.toInt() ??
              (last?['season_number'] as num?)?.toInt();
          if (seasonNumber == null) return;
          final showName = (data['name'] as String?) ?? 'Show';
          final poster = data['poster_path'] as String?;
          final seasonRes = await TMDB.tmdbApi('/tv/$id/season/$seasonNumber');
          final episodes = (seasonRes.data['episodes'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>();
          for (final episode in episodes) {
            final rawDate = episode['air_date'] as String?;
            if (rawDate == null || rawDate.isEmpty) continue;
            final air = DateTime.tryParse(rawDate);
            if (air == null) continue;
            final day = DateTime(air.year, air.month, air.day);
            if (day.isBefore(today) || day.isAfter(cutoff)) continue;
            final still = episode['still_path'] as String?;
            found.add(
              UpcomingItem(
                tmdbId: id,
                showName: showName,
                episodeName: (episode['name'] as String?) ?? 'Episode',
                season:
                    (episode['season_number'] as num?)?.toInt() ?? seasonNumber,
                episode: (episode['episode_number'] as num?)?.toInt() ?? 1,
                airDate: day,
                image: still != null && still.isNotEmpty
                    ? Api.proxyImage('https://image.tmdb.org/t/p/w500$still')
                    : poster != null && poster.isNotEmpty
                    ? Api.proxyImage('https://image.tmdb.org/t/p/w500$poster')
                    : null,
              ),
            );
          }
        } catch (_) {}
      }),
    );

    await Future.wait(
      UserLibrary.watchlistTitles()
          .where((title) => title.type == MediaType.movie)
          .take(30)
          .map((title) async {
            try {
              final movie = await TMDB.movie(title.tmdbId);
              final day = DateTime(
                movie.releaseDate.year,
                movie.releaseDate.month,
                movie.releaseDate.day,
              );
              if (day.isBefore(today) || day.isAfter(cutoff)) return;
              final path = movie.backdropPath ?? movie.posterPath;
              found.add(
                UpcomingItem(
                  tmdbId: title.tmdbId,
                  type: MediaType.movie,
                  showName: movie.title,
                  episodeName: '',
                  season: 0,
                  episode: 0,
                  airDate: day,
                  image: path == null
                      ? null
                      : Api.proxyImage('https://image.tmdb.org/t/p/w500$path'),
                ),
              );
            } catch (_) {}
          }),
    );

    found.sort((a, b) => a.airDate.compareTo(b.airDate));
    if (profileKey == BackendApi.profileCacheKey) items.value = found;
  }
}
