import 'package:petal/models/watch_history/watch_history_parsing.dart';

class EpisodeProgress {
  final int season;
  final int episode;
  final double completion;
  final DateTime? watchedAt;
  final int plays;
  final List<DateTime> watches;

  EpisodeProgress({
    required this.season,
    required this.episode,
    required this.completion,
    this.watchedAt,
    this.plays = 0,
    this.watches = const [],
  });

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) {
    final watchedAt = dateFromUnix(json['watched_at'] as num?);
    final watches = watchDatesFrom(json['watches'], watchedAt);
    return EpisodeProgress(
      season: (json['season'] as num?)?.toInt() ?? 0,
      episode: (json['episode'] as num?)?.toInt() ?? 0,
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
      watchedAt: watches.isNotEmpty ? watches.last : watchedAt,
      plays: (json['plays'] as num?)?.toInt() ?? watches.length,
      watches: watches,
    );
  }
}
