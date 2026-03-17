class TraktLastActivities {
  final DateTime all;
  final TraktMovieActivities movies;
  final TraktEpisodeActivities episodes;
  final TraktShowActivities shows;
  final TraktSeasonActivities seasons;
  final TraktCommentActivities comments;
  final TraktListActivities lists;
  final TraktTimestampActivity watchlist;
  final TraktTimestampActivity favorites;
  final TraktAccountActivities account;
  final TraktTimestampActivity savedFilters;
  final TraktTimestampActivity notes;

  TraktLastActivities({
    required this.all,
    required this.movies,
    required this.episodes,
    required this.shows,
    required this.seasons,
    required this.comments,
    required this.lists,
    required this.watchlist,
    required this.favorites,
    required this.account,
    required this.savedFilters,
    required this.notes,
  });

  factory TraktLastActivities.fromJson(Map<String, dynamic> json) {
    return TraktLastActivities(
      all: DateTime.parse(json['all']),
      movies: TraktMovieActivities.fromJson(json['movies']),
      episodes: TraktEpisodeActivities.fromJson(json['episodes']),
      shows: TraktShowActivities.fromJson(json['shows']),
      seasons: TraktSeasonActivities.fromJson(json['seasons']),
      comments: TraktCommentActivities.fromJson(json['comments']),
      lists: TraktListActivities.fromJson(json['lists']),
      watchlist: TraktTimestampActivity.fromJson(json['watchlist']),
      favorites: TraktTimestampActivity.fromJson(json['favorites']),
      account: TraktAccountActivities.fromJson(json['account']),
      savedFilters: TraktTimestampActivity.fromJson(json['saved_filters']),
      notes: TraktTimestampActivity.fromJson(json['notes']),
    );
  }
}

class TraktTimestampActivity {
  final DateTime updatedAt;

  TraktTimestampActivity({required this.updatedAt});

  factory TraktTimestampActivity.fromJson(Map<String, dynamic> json) => TraktTimestampActivity(updatedAt: DateTime.parse(json['updated_at']));
}

class TraktMovieActivities {
  final DateTime watchedAt;
  final DateTime collectedAt;
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime favoritedAt;
  final DateTime commentedAt;
  final DateTime pausedAt;
  final DateTime hiddenAt;

  TraktMovieActivities({
    required this.watchedAt,
    required this.collectedAt,
    required this.ratedAt,
    required this.watchlistedAt,
    required this.favoritedAt,
    required this.commentedAt,
    required this.pausedAt,
    required this.hiddenAt,
  });

  factory TraktMovieActivities.fromJson(Map<String, dynamic> json) {
    return TraktMovieActivities(
      watchedAt: DateTime.parse(json['watched_at']),
      collectedAt: DateTime.parse(json['collected_at']),
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      favoritedAt: DateTime.parse(json['favorited_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      pausedAt: DateTime.parse(json['paused_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
    );
  }
}

class TraktEpisodeActivities {
  final DateTime watchedAt;
  final DateTime collectedAt;
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime commentedAt;
  final DateTime pausedAt;

  TraktEpisodeActivities({
    required this.watchedAt,
    required this.collectedAt,
    required this.ratedAt,
    required this.watchlistedAt,
    required this.commentedAt,
    required this.pausedAt,
  });

  factory TraktEpisodeActivities.fromJson(Map<String, dynamic> json) {
    return TraktEpisodeActivities(
      watchedAt: DateTime.parse(json['watched_at']),
      collectedAt: DateTime.parse(json['collected_at']),
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      pausedAt: DateTime.parse(json['paused_at']),
    );
  }
}

class TraktShowActivities {
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime favoritedAt;
  final DateTime commentedAt;
  final DateTime hiddenAt;
  final DateTime droppedAt;

  TraktShowActivities({
    required this.ratedAt,
    required this.watchlistedAt,
    required this.favoritedAt,
    required this.commentedAt,
    required this.hiddenAt,
    required this.droppedAt,
  });

  factory TraktShowActivities.fromJson(Map<String, dynamic> json) {
    return TraktShowActivities(
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      favoritedAt: DateTime.parse(json['favorited_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
      droppedAt: DateTime.parse(json['dropped_at']),
    );
  }
}

class TraktSeasonActivities {
  final DateTime ratedAt;
  final DateTime watchlistedAt;
  final DateTime commentedAt;
  final DateTime hiddenAt;

  TraktSeasonActivities({required this.ratedAt, required this.watchlistedAt, required this.commentedAt, required this.hiddenAt});

  factory TraktSeasonActivities.fromJson(Map<String, dynamic> json) {
    return TraktSeasonActivities(
      ratedAt: DateTime.parse(json['rated_at']),
      watchlistedAt: DateTime.parse(json['watchlisted_at']),
      commentedAt: DateTime.parse(json['commented_at']),
      hiddenAt: DateTime.parse(json['hidden_at']),
    );
  }
}

class TraktCommentActivities {
  final DateTime likedAt;
  final DateTime reactedAt;
  final DateTime blockedAt;

  TraktCommentActivities({required this.likedAt, required this.reactedAt, required this.blockedAt});

  factory TraktCommentActivities.fromJson(Map<String, dynamic> json) {
    return TraktCommentActivities(
      likedAt: DateTime.parse(json['liked_at']),
      reactedAt: DateTime.parse(json['reacted_at']),
      blockedAt: DateTime.parse(json['blocked_at']),
    );
  }
}

class TraktListActivities {
  final DateTime likedAt;
  final DateTime reactedAt;
  final DateTime updatedAt;
  final DateTime commentedAt;

  TraktListActivities({required this.likedAt, required this.reactedAt, required this.updatedAt, required this.commentedAt});

  factory TraktListActivities.fromJson(Map<String, dynamic> json) {
    return TraktListActivities(
      likedAt: DateTime.parse(json['liked_at']),
      reactedAt: DateTime.parse(json['reacted_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      commentedAt: DateTime.parse(json['commented_at']),
    );
  }
}

class TraktAccountActivities {
  final DateTime settingsAt;
  final DateTime followedAt;
  final DateTime followingAt;
  final DateTime pendingAt;
  final DateTime requestedAt;

  TraktAccountActivities({required this.settingsAt, required this.followedAt, required this.followingAt, required this.pendingAt, required this.requestedAt});

  factory TraktAccountActivities.fromJson(Map<String, dynamic> json) {
    return TraktAccountActivities(
      settingsAt: DateTime.parse(json['settings_at']),
      followedAt: DateTime.parse(json['followed_at']),
      followingAt: DateTime.parse(json['following_at']),
      pendingAt: DateTime.parse(json['pending_at']),
      requestedAt: DateTime.parse(json['requested_at']),
    );
  }
}
