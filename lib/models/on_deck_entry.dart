import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';

/// One title in On Deck, preserving resume playback when it is available.
class OnDeckEntry {
  final ContinueWatchingItem? progress;
  final LibraryTitle? watchlistTitle;
  final DateTime? lastWatched;

  const OnDeckEntry({this.progress, this.watchlistTitle, this.lastWatched})
    : assert(progress != null || watchlistTitle != null);

  int get tmdbId => progress?.tmdbId ?? watchlistTitle!.tmdbId;
  MediaType get type => progress?.mediaType ?? watchlistTitle!.type;
  String get key => '${type.name}:$tmdbId';
}
