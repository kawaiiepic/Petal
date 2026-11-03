enum CollectionStatus { watching, watched, planned, watchlist, liked }

extension CollectionStatusLabel on CollectionStatus {
  String get label => switch (this) {
    CollectionStatus.watching => 'Watching',
    CollectionStatus.watched => 'Watched',
    CollectionStatus.planned => 'Planned',
    CollectionStatus.watchlist => 'Watchlist',
    CollectionStatus.liked => 'Liked',
  };
}
