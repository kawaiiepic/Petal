
class TraktNextUpItem {
  final TraktShow show;
  final int? season;
  final int? episode;
  final String? title;
  final double? progress;

  TraktNextUpItem({required this.show, this.season, this.episode, this.title, this.progress});

  factory TraktNextUpItem.fromJson(Map<String, dynamic> json) {
    return TraktNextUpItem(show: (TraktShow.fromJson(json['show'])));
  }
}

class TraktShowProgress {
  final double completed;
  final Map<String, dynamic>? nextEpisode;

  TraktShowProgress({required this.completed, this.nextEpisode});

  factory TraktShowProgress.fromJson(Map<String, dynamic> json) {
    return TraktShowProgress(completed: (json['completed'] ?? 0).toDouble(), nextEpisode: json['next_episode']);
  }
}

class TraktMovie {
  final String title;
  final int year;
  final String? imdbId;
  final String? tmdbId;

  TraktMovie({required this.title, required this.year, this.imdbId, this.tmdbId});

  factory TraktMovie.fromJson(Map<String, dynamic> json) {
    final ids = json['ids'] ?? {};
    return TraktMovie(title: json['title'] ?? '', year: json['year'] ?? 0, imdbId: ids['imdb'], tmdbId: ids['tmdb']);
  }
}

class TraktEpisode {
  final int season;
  final int number;
  final String title;

  TraktEpisode({required this.season, required this.number, required this.title});

  factory TraktEpisode.fromJson(Map<String, dynamic> json) {
    return TraktEpisode(season: json['season'] ?? 0, number: json['number'] ?? 0, title: json['title'] ?? '');
  }
}

class TraktShow {
  final String title;
  final int year;
  final String? imdbId;
  final int? traktId;

  TraktShow({required this.title, required this.year, this.imdbId, this.traktId});

  factory TraktShow.fromJson(Map<String, dynamic> json) {
    final ids = json['ids'] ?? {};
    return TraktShow(title: json['title'] ?? '', year: json['year'] ?? 0, imdbId: ids['imdb'], traktId: ids['trakt']);
  }
}

class TraktHistoryItem {
  final DateTime watchedAt;
  final TraktMovie? movie;
  final TraktEpisode? episode;
  final TraktShow? show; // <-- show comes from history item itself

  TraktHistoryItem({required this.watchedAt, this.movie, this.episode, this.show});

  factory TraktHistoryItem.fromJson(Map<String, dynamic> json) {
    return TraktHistoryItem(
      watchedAt: DateTime.parse(json['watched_at']),
      movie: json['movie'] != null ? TraktMovie.fromJson(json['movie']) : null,
      episode: json['episode'] != null ? TraktEpisode.fromJson(json['episode']) : null,
      show: json['show'] != null ? TraktShow.fromJson(json['show']) : null,
    );
  }
}
