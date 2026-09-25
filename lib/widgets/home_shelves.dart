import 'dart:math';

import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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

class OnDeckShelf extends StatelessWidget {
  const OnDeckShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        return ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            final items = list.where(_onDeck).take(12).map((item) {
              final show = item as ShowItem;
              final next = show.nextEpisode!;
              return ShelfItem(tmdbId: show.tmdbId, type: MediaType.show, subtitle: 'S${next.season}E${next.episode}');
            }).toList();
            final seen = {
              for (final item in items) '${item.type.name}:${item.tmdbId}',
              for (final item in list.where(_inProgress)) '${item.mediaType.name}:${item.tmdbId}',
            };
            final extras = UserLibrary.watchlistTitles()
                .where((t) => !seen.contains('${t.type.name}:${t.tmdbId}'))
                .take(4)
                .map((t) => ShelfItem(tmdbId: t.tmdbId, type: t.type, subtitle: 'Watchlist'))
                .toList();
            return PosterShelf(title: 'On deck', items: [...items, ...extras]);
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
        final recent = items.take(12).map((i) => ShelfItem(tmdbId: i.tmdbId, type: i.mediaType)).toList();
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
            PosterShelf(title: 'Recently watched', items: recent),
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
