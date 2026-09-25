import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/pages/collection_home.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum CollectionStatus { watching, watched, planned, watchlist, liked }

extension on CollectionStatus {
  String get label => switch (this) {
    CollectionStatus.watching => 'Watching',
    CollectionStatus.watched => 'Watched',
    CollectionStatus.planned => 'Planned',
    CollectionStatus.watchlist => 'Watchlist',
    CollectionStatus.liked => 'Liked',
  };
}

bool isWatching(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) {
    return item.completion > 0 && item.completion < 1;
  }

  final anyInProgress = item.episodes.any((e) => e.completion > 0 && e.completion < 1);
  if (anyInProgress) return true;

  final anyStarted = item.episodes.any((e) => e.completion > 0);
  if (!anyStarted) return false;

  if (tmdbEpisodeCount != null && tmdbEpisodeCount > 0) {
    final done = item.episodes.where((e) => e.completion >= 1).length;
    return done < tmdbEpisodeCount;
  }
  return true;
}

bool isFinished(WatchHistoryItem item, {int? tmdbEpisodeCount}) {
  if (item.mediaType == MediaType.movie) return item.completion >= 1;

  final anyInProgress = item.episodes.any((e) => e.completion > 0 && e.completion < 1);
  if (anyInProgress) return false;

  final done = item.episodes.where((e) => e.completion >= 1).length;
  if (tmdbEpisodeCount != null && tmdbEpisodeCount > 0) {
    return done >= tmdbEpisodeCount;
  }
  return false;
}

bool isPlanned(WatchHistoryItem item) {
  if (item.mediaType == MediaType.movie) return item.completion <= 0;
  return item.episodes.isEmpty || item.episodes.every((e) => e.completion <= 0);
}

class Collection extends StatefulWidget {
  const Collection({super.key});

  @override
  State<Collection> createState() => _Collection();
}

class _Collection extends State<Collection> {
  @override
  void initState() {
    super.initState();
    BackendCache.fetchWatchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          leading: [BackButton()],
          title: const Text('Collection'),
          trailing: [
            IconButton.ghost(icon: const Icon(LucideIcons.activity), onPressed: () => context.push('/stats')),
          ],
        ),
      ],
      child: const CollectionHome(),
    );
  }
}

class LibraryPosterCard extends StatelessWidget {
  final LibraryTitle title;

  const LibraryPosterCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isShow = title.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(title.tmdbId) : TMDB.movie(title.tmdbId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Avatar(initials: '', borderRadius: 12).asSkeleton();
        }

        final posterPath = (snapshot.data as dynamic).posterPath as String?;
        final name = isShow ? (snapshot.data as dynamic).name as String? : (snapshot.data as dynamic).title as String?;
        if (posterPath == null || posterPath.isEmpty) {
          return const SizedBox.shrink();
        }

        final badge = title.rating == TitleRating.love
            ? 'Loved'
            : title.rating == TitleRating.like
            ? 'Liked'
            : 'Watchlist';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HoverableItem(
                image: CachedNetworkImage(
                  imageUrl: Api.proxyImage('https://image.tmdb.org/t/p/w342$posterPath'),
                  fit: BoxFit.cover,
                ),
                onTap: () => context.push(isShow ? '/series?tmdb=${title.tmdbId}' : '/movie?tmdb=${title.tmdbId}'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name ?? badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        );
      },
    );
  }
}

class CollectionCard extends StatelessWidget {
  final WatchHistoryItem item;
  final Widget poster;
  final dynamic tmdb;
  final CollectionStatus status;

  const CollectionCard({super.key, required this.item, required this.poster, required this.tmdb, required this.status});

  int? get _episodeCount => item.mediaType == MediaType.show ? (tmdb as dynamic).numberOfEpisodes as int? : null;

  String _lastWatched() {
    final d = item.updatedAt.toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  String _progressLabel() {
    if (isFinished(item, tmdbEpisodeCount: _episodeCount)) return 'Finished';
    if (item.mediaType == MediaType.movie) {
      final pct = (item.completion * 100).clamp(0, 100).round();
      if (pct <= 0) return 'Not started';
      return '$pct%';
    }
    final watching = item.episodes.where((e) => e.completion > 0 && e.completion < 1);
    if (watching.isNotEmpty) {
      final e = watching.last;
      return 'S${e.season}E${e.episode} ${(e.completion * 100).round()}%';
    }
    final done = item.episodes.where((e) => e.completion >= 1).length;
    return done == 0 ? 'Not started' : '$done watched';
  }

  double? _episodeCompletion(int season, int episode) {
    for (final e in item.episodes) {
      if (e.season == season && e.episode == episode) return e.completion;
    }
    return null;
  }

  Future<List<TrackerData>> _showTracker() async {
    final showId = item.tmdbId;
    final seasonCount = (tmdb.numberOfSeasons as int?) ?? 1;
    final data = <TrackerData>[];

    for (var s = 1; s <= seasonCount; s++) {
      final season = await TMDB.tvSeason(showId, s);
      final episodes = (season.episodes as List?) ?? const [];
      final count = episodes.isNotEmpty ? episodes.length : season.episodes.length;
      if (count == 0) continue;

      var done = 0;
      var watching = 0;
      for (var ep = 1; ep <= count; ep++) {
        final c = _episodeCompletion(s, ep) ?? 0;
        if (c >= 1) {
          done++;
        } else if (c > 0) {
          watching++;
        }
      }

      data.add(
        TrackerData(
          level: done >= count
              ? TrackerLevel.fine
              : (done > 0 || watching > 0)
              ? TrackerLevel.warning
              : TrackerLevel.unknown,
          tooltip: Text('Season $s  \u00b7  $done/$count'),
        ),
      );
    }
    return data;
  }

  Widget _progressOverlay() {
    if (item.mediaType == MediaType.movie) {
      return LinearProgressIndicator(value: item.completion.clamp(0.0, 1.0), minHeight: 6, borderRadius: BorderRadius.circular(8));
    }

    return FutureBuilder<List<TrackerData>>(
      future: _showTracker(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return ComponentTheme(
          data: const TrackerTheme(itemHeight: 8, gap: 1),
          child: Tracker(data: snap.data!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (status == CollectionStatus.watched && !isFinished(item, tmdbEpisodeCount: _episodeCount)) {
      return const SizedBox.shrink();
    }

    if (status == CollectionStatus.watching && !isWatching(item, tmdbEpisodeCount: _episodeCount)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                poster,
                Positioned(left: 8, right: 8, bottom: 8, child: _progressOverlay()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _progressLabel(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          _lastWatched(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}
