import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/watch_history/recent_watch.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/widgets/home/recent_watch_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class RecentlyWatchedShelf extends StatefulWidget {
  final List<WatchHistoryItem> history;

  const RecentlyWatchedShelf({super.key, required this.history});

  @override
  State<RecentlyWatchedShelf> createState() => _RecentlyWatchedShelfState();
}

class _RecentlyWatchedShelfState extends State<RecentlyWatchedShelf> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    BackendCache.fetchWatchHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _recentWatches(widget.history);
    if (items.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: 'Recently watched',
      child: SizedBox(
        height: 25.h,
        child: ScrollableWidget(
          controller: _controller,
          child: ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) =>
                RecentWatchCard(item: items[index]),
          ),
        ),
      ),
    );
  }
}

List<RecentWatch> _recentWatches(List<WatchHistoryItem> history) {
  final events = <RecentWatch>[];
  for (final item in history) {
    if (item.mediaType == MediaType.movie) {
      events.add(
        RecentWatch(
          tmdbId: item.tmdbId,
          type: MediaType.movie,
          at: item.watchedAt ?? item.updatedAt,
        ),
      );
      continue;
    }
    if (item.episodes.isEmpty) {
      events.add(
        RecentWatch(
          tmdbId: item.tmdbId,
          type: MediaType.show,
          at: item.updatedAt,
        ),
      );
      continue;
    }
    for (final episode in item.episodes) {
      if (episode.completion <= 0 &&
          episode.watches.isEmpty &&
          episode.watchedAt == null)
        continue;
      final at = episode.watches.isNotEmpty
          ? episode.watches.last
          : (episode.watchedAt ?? item.updatedAt);
      events.add(
        RecentWatch(
          tmdbId: item.tmdbId,
          type: MediaType.show,
          season: episode.season,
          episode: episode.episode,
          at: at,
        ),
      );
    }
  }
  events.sort((a, b) => b.at.compareTo(a.at));
  final seen = <int>{};
  final unique = <RecentWatch>[];
  for (final event in events) {
    if (!seen.add(event.tmdbId)) continue;
    unique.add(event);
    if (unique.length >= 12) break;
  }
  return unique;
}
