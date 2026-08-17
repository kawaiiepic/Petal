class NextEpisode {
  final int season;
  final int episode;
  final double completion;

  NextEpisode({required this.season, required this.episode, required this.completion});

  factory NextEpisode.fromJson(Map<String, dynamic> json) {
    return NextEpisode(season: json['season'], episode: json['episode'],
    completion: (json['completion'] as num?)?.toDouble() ?? 0.0);
  }
}

class SeasonEpisode {
  final int episode;
  final double completion;

  SeasonEpisode({required this.episode, required this.completion});

  factory SeasonEpisode.fromJson(Map<String, dynamic> json) {
    return SeasonEpisode(episode: json['episode'], completion: (json['completion'] as num?)?.toDouble() ?? 0.0);
  }
}

class Season {
  final int number;
  final List<SeasonEpisode> episodes;

  Season({required this.number, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(number: json['number'], episodes: (json['episodes'] as List<dynamic>).map((e) => SeasonEpisode.fromJson(e as Map<String, dynamic>)).toList());
  }
}

abstract class ContinueWatchingItem {
  final int tmdbId;
  final String mediaType;

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

  ShowItem({required super.tmdbId, required this.nextEpisode, required this.seasons}) : super(mediaType: 'episode');

  factory ShowItem.fromJson(Map<String, dynamic> json) {
    return ShowItem(
      tmdbId: json['tmdb_id'],
      nextEpisode: json['next_episode'] != null ? NextEpisode.fromJson(json['next_episode']) : null,
      seasons: (json['seasons'] as List<dynamic>).map((s) => Season.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class MovieItem extends ContinueWatchingItem {
  final double completion;

  MovieItem({required super.tmdbId, required this.completion}) : super(mediaType: 'movie');

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(tmdbId: json['tmdb_id'], completion: (json['completion'] as num?)?.toDouble() ?? 0.0);
  }
}
