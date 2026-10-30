import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/episode_progress.dart';
import 'package:petal/models/watch_history/watch_history_parsing.dart';

class WatchHistoryItem {
  final int tmdbId;
  final MediaType mediaType;
  final double completion;
  final DateTime updatedAt;
  final DateTime? watchedAt;
  final int plays;
  final List<DateTime> watches;
  final List<EpisodeProgress> episodes;

  WatchHistoryItem({
    required this.tmdbId,
    required this.mediaType,
    required this.completion,
    required this.updatedAt,
    this.watchedAt,
    this.plays = 0,
    this.watches = const [],
    this.episodes = const [],
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['media_type'] as String? ?? '';
    final mediaType = typeStr == 'movie' ? MediaType.movie : MediaType.show;
    final updatedAt =
        dateFromUnix(json['updated_at'] as num?) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final watchedAt = dateFromUnix(json['watched_at'] as num?);
    final watches = watchDatesFrom(json['watches'], watchedAt);
    final episodes = (json['episodes'] as List<dynamic>? ?? [])
        .map((e) => EpisodeProgress.fromJson(e as Map<String, dynamic>))
        .toList();

    final completion = mediaType == MediaType.movie
        ? (json['completion'] as num?)?.toDouble() ?? 0.0
        : (episodes.isNotEmpty
              ? episodes.last.completion
              : (json['completion'] as num?)?.toDouble() ?? 0.0);

    return WatchHistoryItem(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      mediaType: mediaType,
      completion: completion,
      updatedAt: updatedAt,
      watchedAt: watches.isNotEmpty ? watches.last : watchedAt,
      plays: (json['plays'] as num?)?.toInt() ?? watches.length,
      watches: watches,
      episodes: episodes,
    );
  }
}
