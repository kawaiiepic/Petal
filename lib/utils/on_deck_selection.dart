import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/on_deck_entry.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/watch_progress.dart';

/// Mix resumes and next episodes by activity, then fill spare slots from saved
/// titles. Reserve one watchlist slot even when there are enough active titles.
List<OnDeckEntry> selectOnDeck({
  required List<ContinueWatchingItem> progress,
  required List<WatchHistoryItem> history,
  required List<LibraryTitle> watchlist,
  int limit = 12,
}) {
  if (limit <= 0) return const [];
  String key(int id, MediaType type) => '${type.name}:$id';
  final saved = {
    for (final title in watchlist) key(title.tmdbId, title.type): title,
  };
  final activity = <String, DateTime>{};
  final explicitDates = <String, DateTime>{};
  void record(Map<String, DateTime> dates, String id, DateTime? date) {
    if (date != null && (dates[id] == null || date.isAfter(dates[id]!)))
      dates[id] = date;
  }

  for (final item in history) {
    final id = key(item.tmdbId, item.mediaType);
    record(explicitDates, id, item.lastWatched);
    record(activity, id, item.updatedAt);
    record(activity, id, item.watchedAt);
    for (final date in item.watches) record(activity, id, date);
    for (final episode in item.episodes) {
      record(activity, id, episode.watchedAt);
      for (final date in episode.watches) record(activity, id, date);
    }
  }
  final candidates = <String, OnDeckEntry>{};
  for (final item in progress) {
    final eligible = switch (item) {
      MovieItem movie => WatchProgress.isPartial(movie.completion),
      ShowItem show =>
        show.nextEpisode != null &&
            !WatchProgress.isWatched(show.nextEpisode!.completion),
      _ => false,
    };
    if (!eligible) continue;
    final id = key(item.tmdbId, item.mediaType);
    candidates.putIfAbsent(
      id,
      () => OnDeckEntry(
        progress: item,
        watchlistTitle: saved[id],
        lastWatched: item.lastWatched ?? explicitDates[id] ?? activity[id],
      ),
    );
  }
  int compare(OnDeckEntry a, OnDeckEntry b) {
    final order = (b.lastWatched?.millisecondsSinceEpoch ?? 0).compareTo(
      a.lastWatched?.millisecondsSinceEpoch ?? 0,
    );
    if (order != 0) return order;
    if ((a.progress == null) != (b.progress == null))
      return a.progress == null ? 1 : -1;
    return a.key.compareTo(b.key);
  }

  final active = candidates.values.toList()..sort(compare);
  final extras =
      saved.entries
          .where((entry) => !candidates.containsKey(entry.key))
          .map(
            (entry) => OnDeckEntry(
              watchlistTitle: entry.value,
              lastWatched: explicitDates[entry.key] ?? activity[entry.key],
            ),
          )
          .toList()
        ..sort(compare);
  final selected = active.take(limit - (extras.isNotEmpty ? 1 : 0)).toList();
  for (final entry in extras) {
    if (selected.length == limit) break;
    selected.add(entry);
  }
  if (saved.isNotEmpty &&
      !selected.any((entry) => entry.watchlistTitle != null)) {
    // Prefer a fresh watchlist suggestion; otherwise retain the saved title's
    // resume/next-episode card instead of introducing a duplicate.
    final reserved = extras.isNotEmpty
        ? extras.first
        : active.firstWhere((entry) => entry.watchlistTitle != null);
    if (selected.length == limit) selected.removeLast();
    selected.add(reserved);
  }
  return selected..sort(compare);
}
