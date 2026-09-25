import 'package:petal/models/trakt/enum/media_type.dart';

class NextEpisode {
  final int season;
  final int episode;
  final double completion;

  NextEpisode({required this.season, required this.episode, required this.completion});

  factory NextEpisode.fromJson(Map<String, dynamic> json) {
    return NextEpisode(
      season: (json['season'] as num).toInt(),
      episode: (json['episode'] as num).toInt(),
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SeasonEpisode {
  final int episode;
  final double completion;

  SeasonEpisode({required this.episode, required this.completion});

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) {
    return SeasonEpisode(episode: (json['episode'] as num).toInt(), completion: (json['completion'] as num?)?.toDouble() ?? 0.0);
  }
}

class Season {
  final int number;
  final List<SeasonEpisode> episodes;

  Season({required this.number, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      number: (json['number'] as num).toInt(),
      episodes: (json['episodes'] as List<dynamic>? ?? []).map((e) => SeasonEpisode.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

abstract class ContinueWatchingItem {
  final int tmdbId;
  final MediaType mediaType;

  ContinueWatchingItem({required this.tmdbId, required this.mediaType});

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String;
    if (mediaType == 'movie') {
      return MovieItem.fromJson(json);
    }
    return ShowItem.fromJson(json);
  }
}

class ShowItem extends ContinueWatchingItem {
  final NextEpisode? nextEpisode;
  final List<Season> seasons;

  ShowItem({required super.tmdbId, required this.nextEpisode, required this.seasons}) : super(mediaType: MediaType.show);

  factory ShowItem.fromJson(Map<String, dynamic> json) {
    return ShowItem(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      nextEpisode: json['next_episode'] != null ? NextEpisode.fromJson(json['next_episode'] as Map<String, dynamic>) : null,
      seasons: (json['seasons'] as List<dynamic>? ?? []).map((s) => Season.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class MovieItem extends ContinueWatchingItem {
  final double completion;

  MovieItem({required super.tmdbId, required this.completion}) : super(mediaType: MediaType.movie);

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(tmdbId: (json['tmdb_id'] as num).toInt(), completion: (json['completion'] as num?)?.toDouble() ?? 0.0);
  }
}

class EpisodeProgress {
  final int season;
  final int episode;
  final double completion;
  final DateTime? watchedAt;
  final int plays;

  EpisodeProgress({required this.season, required this.episode, required this.completion, this.watchedAt, this.plays = 0});

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) {
    final watchedRaw = (json['watched_at'] as num?)?.toInt();
    return EpisodeProgress(
      season: (json['season'] as num?)?.toInt() ?? 0,
      episode: (json['episode'] as num?)?.toInt() ?? 0,
      completion: (json['completion'] as num?)?.toDouble() ?? 0.0,
      watchedAt: watchedRaw == null || watchedRaw == 0 ? null : DateTime.fromMillisecondsSinceEpoch(watchedRaw * 1000),
      plays: (json['plays'] as num?)?.toInt() ?? 0,
    );
  }
}

class WatchHistoryItem {
  final int tmdbId;
  final MediaType mediaType;
  final double completion;
  final DateTime updatedAt;
  final DateTime? watchedAt;
  final int plays;
  final List<EpisodeProgress> episodes;

  WatchHistoryItem({
    required this.tmdbId,
    required this.mediaType,
    required this.completion,
    required this.updatedAt,
    this.watchedAt,
    this.plays = 0,
    this.episodes = const [],
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['media_type'] as String? ?? '';
    final mediaType = typeStr == 'movie' ? MediaType.movie : MediaType.show;
    final updatedRaw = (json['updated_at'] as num?)?.toInt() ?? 0;
    final watchedRaw = (json['watched_at'] as num?)?.toInt();

    final episodes = (json['episodes'] as List<dynamic>? ?? []).map((e) => EpisodeProgress.fromJson(e as Map<String, dynamic>)).toList();

    final completion = mediaType == MediaType.movie
        ? (json['completion'] as num?)?.toDouble() ?? 0.0
        : (episodes.isNotEmpty ? episodes.last.completion : (json['completion'] as num?)?.toDouble() ?? 0.0);

    return WatchHistoryItem(
      tmdbId: (json['tmdb_id'] as num).toInt(),
      mediaType: mediaType,
      completion: completion,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedRaw * 1000),
      watchedAt: watchedRaw == null || watchedRaw == 0 ? null : DateTime.fromMillisecondsSinceEpoch(watchedRaw * 1000),
      plays: (json['plays'] as num?)?.toInt() ?? 0,
      episodes: episodes,
    );
  }
}
