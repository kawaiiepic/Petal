import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/widgets/home/recently_watched_shelf.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RecentAndStalledShelves extends StatelessWidget {
  const RecentAndStalledShelves({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, _) {
        final latest = <int, WatchHistoryItem>{};
        for (final item in history) {
          final existing = latest[item.tmdbId];
          if (existing == null || item.updatedAt.isAfter(existing.updatedAt))
            latest[item.tmdbId] = item;
        }
        final items = latest.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        final stalled = items
            .where((i) {
              if (!i.updatedAt.isBefore(cutoff)) return false;
              if (i.mediaType == MediaType.movie)
                return i.completion > 0 && i.completion < 1;
              return i.episodes.any(
                (e) => e.completion > 0 && e.completion < 1,
              );
            })
            .take(12)
            .map(
              (i) => ShelfItem(
                tmdbId: i.tmdbId,
                type: i.mediaType,
                subtitle: 'Stalled',
              ),
            )
            .toList();
        final rewatched = [...items]
          ..sort((a, b) {
            final ap = a.plays + a.episodes.fold<int>(0, (s, e) => s + e.plays);
            final bp = b.plays + b.episodes.fold<int>(0, (s, e) => s + e.plays);
            return bp.compareTo(ap);
          });
        final topRewatched = rewatched
            .where((i) {
              final plays =
                  i.plays + i.episodes.fold<int>(0, (s, e) => s + e.plays);
              return plays > 1;
            })
            .take(12)
            .map((i) => ShelfItem(tmdbId: i.tmdbId, type: i.mediaType))
            .toList();

        return Column(
          children: [
            RecentlyWatchedShelf(history: history),
            PosterShelf(title: 'Stalled', items: stalled),
            PosterShelf(title: 'Most rewatched', items: topRewatched),
          ],
        );
      },
    );
  }
}
