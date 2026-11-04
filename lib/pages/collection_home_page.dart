import 'dart:async';

import 'package:petal/api/api.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/collection_progress.dart';
import 'package:petal/api/collection_history.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/collection/collection_card.dart';
import 'package:petal/widgets/collection/empty_collection_row.dart';
import 'package:petal/widgets/collection/library_poster_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionHomePage extends StatefulWidget {
  const CollectionHomePage({super.key});

  @override
  State<CollectionHomePage> createState() => _CollectionHomePageState();
}

class _CollectionHomePageState extends State<CollectionHomePage> {
  final Set<String> _open = {'watching', 'watchlist'};
  List<CollectionHistoryEntry> _entries = [];
  int _generation = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reloadHistory();
    BackendCache.watchHistory.addListener(_reloadHistory);
  }

  void _reloadHistory() {
    final generation = ++_generation;
    unawaited(loadCollectionHistory(
      BackendCache.watchHistory.value,
      isCurrent: () => mounted && generation == _generation,
      onUpdate: (entries) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _entries = entries;
          _loading = false;
        });
      },
    ));
  }

  @override
  void dispose() {
    _generation++;
    BackendCache.watchHistory.removeListener(_reloadHistory);
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_open.contains(id)) {
        _open.remove(id);
      } else {
        _open.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading;
    final items = _entries;
    return ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            return ValueListenableBuilder(
              valueListenable: UserLibrary.ratings,
              builder: (context, _, __) {
                final watching = items
                    .where(
                      (entry) => isWatching(
                        entry.item,
                        tmdbEpisodeCount: entry.episodeCount,
                      ),
                    )
                    .toList();
                final watched = items
                    .where(
                      (entry) => isFinished(
                        entry.item,
                        tmdbEpisodeCount: entry.episodeCount,
                      ),
                    )
                    .toList();
                final planned = items
                    .where((entry) => isPlanned(entry.item))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                  children: [
                    _section(
                      context,
                      id: 'watching',
                      title: 'Watching',
                      count: loading ? null : watching.length,
                      child: _historyRow(watching, loading: loading),
                    ),
                    _section(
                      context,
                      id: 'watchlist',
                      title: 'Watchlist',
                      count: UserLibrary.watchlistTitles().length,
                      child: _libraryRow(UserLibrary.watchlistTitles()),
                    ),
                    _section(
                      context,
                      id: 'liked',
                      title: 'Liked',
                      count: UserLibrary.ratedTitles().length,
                      child: _libraryRow(UserLibrary.ratedTitles()),
                    ),
                    _section(
                      context,
                      id: 'watched',
                      title: 'Watched',
                      count: loading ? null : watched.length,
                      child: _historyRow(watched, loading: loading),
                    ),
                    _section(
                      context,
                      id: 'planned',
                      title: 'Planned',
                      count: loading ? null : planned.length,
                      child: _historyRow(planned, loading: loading),
                    ),
                  ],
                );
              },
            );
          },
        );
  }

  Widget _section(
    BuildContext context, {
    required String id,
    required String title,
    required int? count,
    required Widget child,
  }) {
    final open = _open.contains(id);
    return Column(
      children: [
        Button(
          style: ButtonVariance.ghost,
          onPressed: () => _toggle(id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  count?.toString() ?? '…',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 8),
                Icon(
                  open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (open) child,
      ],
    );
  }

  Widget _historyRow(
    List<CollectionHistoryEntry> entries, {
    bool loading = false,
  }) {
    if (entries.isEmpty && !loading)
      return const EmptyCollectionRow(text: 'Nothing here yet');
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: loading ? 5 : entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (loading)
            return const SizedBox(
              width: 118,
              child: MediaCard(isLoading: true),
            );
          final entry = entries[index];
          final item = entry.item;
          final path = entry.posterPath;
          return SizedBox(
            key: ValueKey('collection-${item.mediaType.name}-${item.tmdbId}'),
            width: 118,
            child: CollectionCard(
              item: item,
              tmdb: entry.metadata,
              poster: MediaCard(
                imageUrl: path == null || path.isEmpty
                    ? null
                    : Api.proxyImage(
                        path.startsWith('http')
                            ? path
                            : 'https://image.tmdb.org/t/p/w342$path',
                      ),
                target: MediaCardTarget(
                  tmdbId: item.tmdbId,
                  type: item.mediaType,
                  totalEpisodes: entry.episodeCount,
                ),
                onTap: () => context.push(
                  item.mediaType == MediaType.show
                      ? '/series?tmdb=${item.tmdbId}'
                      : '/movie?tmdb=${item.tmdbId}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _libraryRow(List<LibraryTitle> titles) {
    if (titles.isEmpty)
      return const EmptyCollectionRow(text: 'Nothing here yet');
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: titles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: 118,
          child: LibraryPosterCard(title: titles[index]),
        ),
      ),
    );
  }
}
