import 'dart:async';

import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/collection_history.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/utils/collection_progress.dart';
import 'package:petal/widgets/collection/collection_card.dart';
import 'package:petal/widgets/collection/empty_collection_row.dart';
import 'package:petal/widgets/collection/library_poster_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionHomePage extends StatefulWidget {
  const CollectionHomePage({super.key});

  @override
  State<CollectionHomePage> createState() => _CollectionHomePageState();
}

class _CollectionHomePageState extends State<CollectionHomePage> {
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
    unawaited(
      loadCollectionHistory(
        BackendCache.watchHistory.value,
        isCurrent: () => mounted && generation == _generation,
        onUpdate: (entries) {
          if (!mounted || generation != _generation) return;
          setState(() {
            _entries = entries;
            _loading = false;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    BackendCache.watchHistory.removeListener(_reloadHistory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([UserLibrary.watchlist, UserLibrary.ratings]),
    builder: (context, _) {
      final watchlist = UserLibrary.watchlistTitles();
      final liked = UserLibrary.ratedTitles();
      return ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _historyShelf(
            'Watching',
            _entries
                .where(
                  (e) => isWatching(e.item, tmdbEpisodeCount: e.episodeCount),
                )
                .toList(),
          ),
          _libraryShelf('Watchlist', watchlist),
          _libraryShelf('Liked', liked),
          _historyShelf(
            'Watched',
            _entries
                .where(
                  (e) => isFinished(e.item, tmdbEpisodeCount: e.episodeCount),
                )
                .toList(),
          ),
          _historyShelf(
            'Planned',
            _entries.where((e) => isPlanned(e.item)).toList(),
          ),
        ],
      );
    },
  );

  Widget _shelf(
    String title,
    int? count, {
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    bool landscape = false,
  }) => HomeSection(
    title: title,
    editorial: true,
    padding: const EdgeInsets.only(top: 0, bottom: 4),
    trailing: count == null ? null : SecondaryBadge(child: Text('$count')),
    child: itemCount == 0
        ? const EmptyCollectionRow(text: 'Nothing here yet')
        : MediaShelf(
            orientation: landscape
                ? Orientation.landscape
                : Orientation.portrait,
            cardHeight: landscape ? 148 : 190,
            cardWidth: landscape ? null : 118,
            spacing: 10,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
  );

  Widget _libraryShelf(String title, List<LibraryTitle> titles) => _shelf(
    title,
    titles.length,
    itemCount: titles.length,
    itemBuilder: (_, index) => LibraryPosterCard(title: titles[index]),
  );

  Widget _historyShelf(String title, List<CollectionHistoryEntry> entries) =>
      _shelf(
        title,
        _loading ? null : entries.length,
        itemCount: _loading ? 5 : entries.length,
        landscape: true,
        itemBuilder: (context, index) {
          if (_loading) {
            return const MediaCard(
              orientation: Orientation.landscape,
              isLoading: true,
            );
          }
          final entry = entries[index];
          final item = entry.item;
          return CollectionCard(
            key: ValueKey('collection-${item.mediaType.name}-${item.tmdbId}'),
            entry: entry,
          );
        },
      );
}
