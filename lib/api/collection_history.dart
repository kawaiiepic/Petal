import 'dart:async';

import 'package:petal/api/collection_metadata.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';

/// Publish cached entries first, then refine partitions as counts arrive.
Future<List<CollectionHistoryEntry>> loadCollectionHistory(
  List<WatchHistoryItem> history, {
  void Function(List<CollectionHistoryEntry>)? onUpdate,
  bool Function()? isCurrent,
}) async {
  final latest = <String, WatchHistoryItem>{};
  for (final item in history) {
    final key = '${item.mediaType.name}:${item.tmdbId}';
    if (latest[key] == null || item.updatedAt.isAfter(latest[key]!.updatedAt))
      latest[key] = item;
  }
  final items = latest.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  await CollectionMetadata.restore();
  final entries = items.map((item) => CollectionHistoryEntry(
    item: item,
    metadata: CollectionMetadata.peek(item.tmdbId, item.mediaType),
  )).toList();
  onUpdate?.call(List.of(entries));
  Timer? publishTimer;
  void publish() {
    publishTimer ??= Timer(const Duration(milliseconds: 50), () {
      publishTimer = null;
      if (isCurrent?.call() ?? true) onUpdate?.call(List.of(entries));
    });
  }
  var next = 0;
  Future<void> worker() async {
    while (next < items.length && (isCurrent?.call() ?? true)) {
      final index = next++;
      final item = items[index];
      try {
        final metadata = await CollectionMetadata.get(item.tmdbId, item.mediaType);
        entries[index] = CollectionHistoryEntry(item: item, metadata: metadata);
      } catch (_) {
        // A failed metadata lookup still gets a visible, usable card.
        entries[index] = CollectionHistoryEntry(item: item);
      }
      publish();
    }
  }

  await Future.wait(List.generate(items.length.clamp(0, 6), (_) => worker()));
  publishTimer?.cancel();
  if (isCurrent?.call() ?? true) onUpdate?.call(List.of(entries));
  return entries;
}
