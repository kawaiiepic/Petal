import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

/// Resolve counts before partitioning rows so rejected cards leave no slots.
Future<List<CollectionHistoryEntry>> loadCollectionHistory(
  List<WatchHistoryItem> history,
) async {
  final latest = <String, WatchHistoryItem>{};
  for (final item in history) {
    final key = '${item.mediaType.name}:${item.tmdbId}';
    if (latest[key] == null || item.updatedAt.isAfter(latest[key]!.updatedAt))
      latest[key] = item;
  }
  final items = latest.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final entries = List<CollectionHistoryEntry?>.filled(items.length, null);
  var next = 0;
  Future<void> worker() async {
    while (next < items.length) {
      final index = next++;
      final item = items[index];
      try {
        final metadata = item.mediaType == MediaType.show
            ? await TMDB.tvShow(item.tmdbId)
            : await TMDB.movie(item.tmdbId);
        entries[index] = CollectionHistoryEntry(item: item, metadata: metadata);
      } catch (_) {
        // A failed metadata lookup still gets a visible, usable card.
        entries[index] = CollectionHistoryEntry(item: item);
      }
    }
  }

  await Future.wait(List.generate(items.length.clamp(0, 6), (_) => worker()));
  return entries.cast<CollectionHistoryEntry>();
}
