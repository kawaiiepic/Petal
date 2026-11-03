import 'package:petal/models/media_type.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/tmdb/tmdb_season.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';

/// Resolve a playable aired episode, with history taking priority over next-up.
abstract final class ShowPlayback {
  static Future<({Episode? episode, bool rewatch})> resolve({
    required TmdbShow show,
    required List<WatchHistoryItem> history,
    required List<ContinueWatchingItem> nextUp,
    required Future<TmdbSeason> Function(int) loadSeason,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final completion = <String, double>{};
    final current = nextUp.whereType<ShowItem>()
        .where((item) => item.tmdbId == show.id).toList();
    for (final item in current) {
      for (final season in item.seasons) {
        for (final episode in season.episodes) {
          completion['${season.number}:${episode.episode}'] = episode.completion;
        }
      }
    }
    final records = history.where((item) => item.tmdbId == show.id && item.mediaType == MediaType.show)
        .toList()..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    for (final item in records) {
      for (final episode in item.episodes) {
        completion['${episode.season}:${episode.episode}'] = episode.completion;
      }
    }
    final seasons = <int, TmdbSeason>{};
    Future<TmdbSeason> season(int number) async =>
        seasons[number] ??= await loadSeason(number);
    Future<bool> aired(Episode target) async {
      final details = await season(target.seasonNumber);
      return details.episodes.any((ep) =>
          ep.episodeNumber == target.episodeNumber &&
          ep.airDate != null && !ep.airDate!.isAfter(today));
    }
    final candidates = <Episode>[
      for (final item in current)
        if (item.nextEpisode != null &&
            !WatchProgress.isWatched(completion['${item.nextEpisode!.season}:${item.nextEpisode!.episode}'] ?? item.nextEpisode!.completion))
          Episode(seasonNumber: item.nextEpisode!.season,
              episodeNumber: item.nextEpisode!.episode),
    ];
    final partial = completion.entries.where((entry) =>
        WatchProgress.isPartial(entry.value)).map((entry) {
      final numbers = entry.key.split(':').map(int.parse).toList();
      return Episode(seasonNumber: numbers[0], episodeNumber: numbers[1]);
    }).toList()..sort((a, b) {
      final order = b.seasonNumber.compareTo(a.seasonNumber);
      return order != 0 ? order : b.episodeNumber.compareTo(a.episodeNumber);
    });
    final currentResumes = <Episode>[
      for (final item in current)
        if (item.nextEpisode != null &&
            WatchProgress.isPartial(completion['${item.nextEpisode!.season}:${item.nextEpisode!.episode}'] ?? item.nextEpisode!.completion))
          Episode(seasonNumber: item.nextEpisode!.season,
              episodeNumber: item.nextEpisode!.episode),
    ];
    // Resume an unfinished episode before starting the next unwatched episode.
    for (final target in [...currentResumes, ...partial, ...candidates]) {
      if (await aired(target)) return (episode: target, rewatch: false);
    }
    final regular = show.seasons.where((s) => s.seasonNumber > 0).toList()
        ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    Episode? firstAired;
    for (final summary in regular) {
      final episodes = [...(await season(summary.seasonNumber)).episodes]
          ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      for (final ep in episodes) {
        if (ep.airDate == null || ep.airDate!.isAfter(today)) continue;
        final target = Episode(seasonNumber: ep.seasonNumber,
            episodeNumber: ep.episodeNumber);
        firstAired ??= target;
        if (!WatchProgress.isWatched(completion['${ep.seasonNumber}:${ep.episodeNumber}'] ?? 0)) {
          return (episode: target, rewatch: false);
        }
      }
    }
    return (episode: firstAired, rewatch: firstAired != null);
  }
}
