import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum CollectionStatus { watching, watched, planned }

extension on CollectionStatus {
  String get label => switch (this) {
    CollectionStatus.watching => 'Watching',
    CollectionStatus.watched => 'Watched',
    CollectionStatus.planned => 'Planned',
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
  int index = 0;
  CollectionStatus status = CollectionStatus.watching;

  @override
  void initState() {
    super.initState();
    BackendCache.fetchWatchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(leading: [BackButton()], title: Text('Collection')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Tabs(
                    index: index,
                    onChanged: (value) => setState(() => index = value),
                    children: const [
                      TabItem(child: Text('All')),
                      TabItem(child: Text('Shows')),
                      TabItem(child: Text('Movies')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 110, maxWidth: 132),
                child: Select<CollectionStatus>(
                  value: status,
                  itemBuilder: (context, item) => Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  popup: SelectPopup(
                    items: SelectItemList(
                      children: [
                        for (final s in CollectionStatus.values)
                          SelectItemButton(value: s, child: Text(s.label)),
                      ],
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
      child: WatchList(filterIndex: index, status: status),
    );
  }
}

class WatchList extends StatelessWidget {
  final int filterIndex;
  final CollectionStatus status;

  const WatchList({super.key, required this.filterIndex, required this.status});

  int _columns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 3;
    if (width < 700) return 4;
    if (width < 1100) return 5;
    return 6;
  }

  bool _matchesStatus(WatchHistoryItem item) => switch (status) {
    CollectionStatus.watching => isWatching(item),
    CollectionStatus.watched => item.mediaType == MediaType.movie && isFinished(item),
    CollectionStatus.planned => isPlanned(item),
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, child) {
        final latestByTmdbId = <int, WatchHistoryItem>{};
        for (final item in history) {
          final existing = latestByTmdbId[item.tmdbId];
          if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
            latestByTmdbId[item.tmdbId] = item;
          }
        }

        var deduped = latestByTmdbId.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (filterIndex == 1) {
          deduped = deduped.where((i) => i.mediaType == MediaType.show).toList();
        } else if (filterIndex == 2) {
          deduped = deduped.where((i) => i.mediaType == MediaType.movie).toList();
        }

        deduped = deduped.where(_matchesStatus).toList();

        if (deduped.isEmpty) {
          return const Center(child: Text('Nothing here yet'));
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: deduped.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns(context),
            childAspectRatio: 2 / 3.15,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = deduped[index];
            final isShow = item.mediaType == MediaType.show;

            return FutureBuilder(
              future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Avatar(initials: '', borderRadius: 12).asSkeleton();
                }

                final posterPath = (snapshot.data as dynamic).posterPath as String?;
                if (posterPath == null || posterPath.isEmpty) {
                  return const SizedBox.shrink();
                }

                return CollectionCard(
                  item: item,
                  tmdb: snapshot.data,
                  status: status,
                  poster: HoverableItem(
                    image: CachedNetworkImage(imageUrl: 'https://image.tmdb.org/t/p/w342$posterPath', fit: BoxFit.cover),
                  ),
                );
              },
            );
          },
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
          tooltip: Text('Season $s  ·  $done/$count'),
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
