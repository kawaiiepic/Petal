import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:petal/widgets/trakt/trakt_next_up.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

bool _inProgress(ContinueWatchingItem item) {
  if (item is MovieItem) return item.completion > 0 && item.completion < 1;
  if (item is ShowItem) {
    final next = item.nextEpisode;
    return next != null && next.completion > 0 && next.completion < 1;
  }
  return false;
}

bool _onDeck(ContinueWatchingItem item) {
  if (item is ShowItem) {
    final next = item.nextEpisode;
    return next != null && next.completion <= 0;
  }
  return false;
}

class OnDeckShelf extends StatefulWidget {
  const OnDeckShelf({super.key});

  @override
  State<OnDeckShelf> createState() => _OnDeckShelfState();
}

class _OnDeckShelfState extends State<OnDeckShelf> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _onAuth();
    BackendApi.authState.addListener(_onAuth);
  }

  void _onAuth() {
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
    }
  }

  @override
  void dispose() {
    BackendApi.authState.removeListener(_onAuth);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        final onDeck = list.where(_onDeck).take(12).toList();
        if (onDeck.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'On deck',
          child: SizedBox(
            height: 25.h,
            child: ScrollableWidget(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: onDeck.length,
                itemBuilder: (context, index) {
                  final state = onDeck[index];
                  return SizedBox(
                    width: 55.w,
                    child: TraktNextUpItem(key: ValueKey('deck-${state.mediaType}-${state.tmdbId}'), state: state),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WatchlistLandscapeCard extends StatelessWidget {
  final LibraryTitle item;

  const _WatchlistLandscapeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        String name = '';
        if (snapshot.hasData) {
          if (isShow) {
            final show = snapshot.data as dynamic;
            final backdrop = show.backdropPath as String?;
            final poster = show.posterPath as String?;
            name = (show.name as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty) ? backdrop : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else {
            final movie = snapshot.data as dynamic;
            final backdrop = movie.backdropPath as String?;
            final poster = movie.posterPath as String?;
            name = (movie.title as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty) ? backdrop : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          }
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
          child: Column(
            spacing: 8,
            children: [
              Expanded(
                child: HoverableItem(
                  orientation: Orientation.landscape,
                  onTap: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                  contextItems: [
                    MenuButton(
                      leading: const Icon(LucideIcons.play),
                      onPressed: (_) => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                      child: const Text('Play'),
                    ),
                    MenuButton(
                      leading: const Icon(LucideIcons.info),
                      onPressed: (_) => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                      child: const Text('More Info'),
                    ),
                  ],
                  image: image == null
                      ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                      : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
                child: Column(
                  children: [
                    Text(name.isEmpty ? 'Loading...' : name, style: TextStyle(fontSize: 15.px), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Start now', style: TextStyle(fontSize: 15.px), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StartNowShelf extends StatefulWidget {
  const StartNowShelf({super.key});

  @override
  State<StartNowShelf> createState() => _StartNowShelfState();
}

class _StartNowShelfState extends State<StartNowShelf> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        return ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            final seen = {
              for (final item in list) '${item.mediaType.name}:${item.tmdbId}',
            };
            final items = UserLibrary.watchlistTitles().where((title) => title.type == MediaType.show && !seen.contains('${title.type.name}:${title.tmdbId}')).take(12).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return HomeSection(
              title: 'Start now',
              child: SizedBox(
                height: 25.h,
                child: ScrollableWidget(
                  controller: _controller,
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) => SizedBox(
                      width: 55.w,
                      child: _WatchlistLandscapeCard(item: items[index]),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class WatchlistShelf extends StatelessWidget {
  const WatchlistShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.watchlist,
      builder: (context, _, __) {
        final items = UserLibrary.watchlistTitles().take(12).map((t) => ShelfItem(tmdbId: t.tmdbId, type: t.type)).toList();
        return PosterShelf(title: 'From your watchlist', items: items);
      },
    );
  }
}

class LikedShelf extends StatelessWidget {
  const LikedShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.ratings,
      builder: (context, _, __) {
        final items = UserLibrary.ratedTitles().take(12).map((t) => ShelfItem(tmdbId: t.tmdbId, type: t.type, subtitle: t.rating == TitleRating.love ? 'Loved' : 'Liked')).toList();
        return PosterShelf(title: 'Liked', items: items);
      },
    );
  }
}

class _RecentWatch {
  final int tmdbId;
  final MediaType type;
  final int? season;
  final int? episode;
  final DateTime at;

  const _RecentWatch({required this.tmdbId, required this.type, required this.at, this.season, this.episode});
}

List<_RecentWatch> _recentWatches(List<WatchHistoryItem> history) {
  final events = <_RecentWatch>[];
  for (final item in history) {
    if (item.mediaType == MediaType.movie) {
      events.add(_RecentWatch(tmdbId: item.tmdbId, type: MediaType.movie, at: item.watchedAt ?? item.updatedAt));
      continue;
    }
    if (item.episodes.isEmpty) {
      events.add(_RecentWatch(tmdbId: item.tmdbId, type: MediaType.show, at: item.updatedAt));
      continue;
    }
    for (final episode in item.episodes) {
      if (episode.completion <= 0 && episode.watches.isEmpty && episode.watchedAt == null) continue;
      final at = episode.watches.isNotEmpty ? episode.watches.last : (episode.watchedAt ?? item.updatedAt);
      events.add(_RecentWatch(tmdbId: item.tmdbId, type: MediaType.show, season: episode.season, episode: episode.episode, at: at));
    }
  }
  events.sort((a, b) => b.at.compareTo(a.at));
  final seen = <int>{};
  final unique = <_RecentWatch>[];
  for (final event in events) {
    if (!seen.add(event.tmdbId)) continue;
    unique.add(event);
    if (unique.length >= 12) break;
  }
  return unique;
}

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
            itemBuilder: (context, index) => SizedBox(
              width: 55.w,
              child: _RecentWatchCard(item: items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentWatchCard extends StatelessWidget {
  final _RecentWatch item;

  const _RecentWatchCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show && item.season != null && item.episode != null;
    return FutureBuilder(
      future: isShow
          ? Future.wait<dynamic>([TMDB.tvShow(item.tmdbId), TMDB.tvEpisode(item.tmdbId, item.season!, item.episode!)])
          : item.type == MediaType.show
              ? TMDB.tvShow(item.tmdbId)
              : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        String title = '';
        String subtitle = WatchMeta.relative(item.at);

        if (snapshot.hasData) {
          if (isShow) {
            final parts = snapshot.data as List<dynamic>;
            final show = parts[0] as TmdbShow;
            final episode = parts[1] as TmdbEpisode;
            title = show.name;
            subtitle = 'S${item.season} \u00b7 E${item.episode} - ${episode.name}';
            final still = episode.stillPath;
            final backdrop = show.backdropPath;
            final path = (still != null && still.isNotEmpty) ? still : backdrop;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else if (item.type == MediaType.show) {
            final show = snapshot.data as TmdbShow;
            title = show.name;
            final path = show.backdropPath;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else {
            final movie = snapshot.data as TmdbMovie;
            title = movie.title;
            final path = movie.backdropPath ?? movie.posterPath;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http') ? Api.proxyImage(path) : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(2.w, 8, 2.w, 8),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HoverableItem(
                  orientation: Orientation.landscape,
                  onTap: () => context.push(item.type == MediaType.show ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                  extraWidget: Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: WatchMetaOverlay(
                      durationLabel: isShow ? 'S${item.season} \u00b7 E${item.episode}' : null,
                      remainingLabel: WatchMeta.relative(item.at),
                    ),
                  ),
                  image: image == null
                      ? Avatar(initials: '', borderRadius: 12).asSkeleton()
                      : CachedNetworkImage(imageUrl: image, fit: BoxFit.cover),
                ),
              ),
              SizedBox(
                height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.isEmpty ? 'Loading...' : title, style: TextStyle(fontSize: 15.px, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: TextStyle(fontSize: 13.px, color: Colors.white.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
          if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) latest[item.tmdbId] = item;
        }
        final items = latest.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final cutoff = DateTime.now().subtract(const Duration(days: 14));
        final stalled = items.where((i) {
          if (!i.updatedAt.isBefore(cutoff)) return false;
          if (i.mediaType == MediaType.movie) return i.completion > 0 && i.completion < 1;
          return i.episodes.any((e) => e.completion > 0 && e.completion < 1);
        }).take(12).map((i) => ShelfItem(tmdbId: i.tmdbId, type: i.mediaType, subtitle: 'Stalled')).toList();
        final rewatched = [...items]..sort((a, b) {
          final ap = a.plays + a.episodes.fold<int>(0, (s, e) => s + e.plays);
          final bp = b.plays + b.episodes.fold<int>(0, (s, e) => s + e.plays);
          return bp.compareTo(ap);
        });
        final topRewatched = rewatched.where((i) {
          final plays = i.plays + i.episodes.fold<int>(0, (s, e) => s + e.plays);
          return plays > 1;
        }).take(12).map((i) => ShelfItem(tmdbId: i.tmdbId, type: i.mediaType)).toList();

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

class BecauseYouWatchedShelf extends StatefulWidget {
  const BecauseYouWatchedShelf({super.key});

  @override
  State<BecauseYouWatchedShelf> createState() => _BecauseYouWatchedShelfState();
}

class _BecauseYouWatchedShelfState extends State<BecauseYouWatchedShelf> {
  Future<List<ShelfItem>>? _future;
  String _title = 'Because you watched';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ShelfItem>> _load() async {
    final history = [...BackendCache.watchHistory.value]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (history.isEmpty) return const [];
    final seed = history.first;
    try {
      if (seed.mediaType == MediaType.show) {
        final show = await TMDB.tvShow(seed.tmdbId);
        _title = 'Because you watched ${show.name}';
        final recs = show.recommendations?.results.take(12) ?? const [];
        return recs.map((r) => ShelfItem(tmdbId: r.id, type: MediaType.show)).toList();
      }
      final movie = await TMDB.movie(seed.tmdbId);
      _title = 'Because you watched ${movie.title}';
      final recs = movie.recommendations?.results.take(12) ?? const [];
      return recs.map((r) => ShelfItem(tmdbId: r.id, type: MediaType.movie)).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) => PosterShelf(title: _title, items: snapshot.data ?? const []),
    );
  }
}

class SurpriseWatchlistButton extends StatelessWidget {
  const SurpriseWatchlistButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserLibrary.watchlist,
      builder: (context, _, __) {
        final titles = UserLibrary.watchlistTitles();
        if (titles.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Button.secondary(
            onPressed: () {
              final pick = titles[Random().nextInt(titles.length)];
              context.push(pick.type == MediaType.show ? '/series?tmdb=${pick.tmdbId}' : '/movie?tmdb=${pick.tmdbId}');
            },
            child: const Text('Surprise me from my watchlist'),
          ),
        );
      },
    );
  }
}
