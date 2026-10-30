class LibraryImportReport {
  int moviesWatched = 0;
  int episodesWatched = 0;
  int watchlisted = 0;
  int rated = 0;
  int skipped = 0;
  int existing = 0;
  String source = 'auto';

  String get summary =>
      '[$source] Added $moviesWatched movies, '
      '$episodesWatched episodes, $watchlisted watchlist, '
      '$rated ratings. Already present $existing. '
      'Skipped $skipped.';
}
