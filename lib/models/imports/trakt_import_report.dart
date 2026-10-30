class TraktImportReport {
  int moviesWatched = 0;
  int episodesWatched = 0;
  int watchlisted = 0;
  int rated = 0;
  int skipped = 0;

  String get summary =>
      'Imported $moviesWatched movies watched, $episodesWatched episodes watched, $watchlisted watchlist, $rated ratings. Skipped $skipped.';
}
