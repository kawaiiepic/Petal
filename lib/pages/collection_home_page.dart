import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:petal/models/library/collection_section.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
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
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionHomePage extends StatefulWidget {
  final CollectionSection? section;
  const CollectionHomePage({super.key, this.section});

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
      final watching = _entries.where((e) =>
        isWatching(e.item, tmdbEpisodeCount: e.episodeCount)).toList();
      final watched = _entries.where((e) =>
        isFinished(e.item, tmdbEpisodeCount: e.episodeCount)).toList();
      final planned = _entries.where((e) => isPlanned(e.item)).toList();
      final section = widget.section;
      if (section != null) {
        final content = switch (section) {
          CollectionSection.watching => _historyShelf(section, watching),
          CollectionSection.watchlist => _libraryShelf(section, watchlist),
          CollectionSection.liked => _libraryShelf(section, liked),
          CollectionSection.watched => _historyShelf(section, watched),
          CollectionSection.planned => _historyShelf(section, planned),
        };
        return ListView(
          key: PageStorageKey('collection:${section.name}'),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [content],
        );
      }
      return ListView(
        key: PageStorageKey('collection:${section?.name ?? 'all'}'),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _historyShelf(CollectionSection.watching, watching),
          _libraryShelf(CollectionSection.watchlist, watchlist),
          _libraryShelf(CollectionSection.liked, liked),
          _historyShelf(CollectionSection.watched, watched),
          _historyShelf(CollectionSection.planned, planned),
        ],
      );
    },
  );

  Widget _shelf(
    CollectionSection section,
    int? count, {
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    bool landscape = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (widget.section == null) Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
        child: Row(
          spacing: 8,
          children: [
            Flexible(
              child: PetalButton.ghost(
                alignment: Alignment.centerLeft,
                onPressed: () => context.push(section.route),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Flexible(child: Text(section.label, style: TextStyle(
                      color: Theme.of(context).colorScheme.foreground,
                      fontSize: 21, fontWeight: FontWeight.w700,
                    ))),
                    Icon(LucideIcons.chevronRight, size: 16,
                      color: Theme.of(context).colorScheme.mutedForeground),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (count != null) SecondaryBadge(child: Text('$count')),
          ],
        ),
      ),
      if (itemCount == 0)
        const EmptyCollectionRow(text: 'Nothing here yet')
      else
        LayoutBuilder(
          builder: (context, constraints) {
            // Size the slot from the artwork width plus its two caption lines.
            // Do not calculate landscape width from the caption-inclusive height.
            final available = (constraints.maxWidth - 40).clamp(1.0, 240.0).toDouble();
            final width = landscape ? available : 118.0;
            final artworkHeight = landscape ? width * 9 / 16 : width * 4 / 3;
            final captionHeight = MediaQuery.textScalerOf(context).scale(32) + 6;
            if (widget.section != null) {
              final gap = 12.0;
              final contentWidth = math.max(1.0, constraints.maxWidth - 40);
              final targetWidth = landscape ? 220.0 : 145.0;
              final columns = math.max(1, ((contentWidth + gap) / (targetWidth + gap)).floor());
              final cellWidth = (contentWidth - gap * (columns - 1)) / columns;
              final cellHeight = (landscape ? cellWidth * 9 / 16 : cellWidth * 4 / 3) + captionHeight;
              return GridView.builder(
                primary: false, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, mainAxisExtent: cellHeight,
                  crossAxisSpacing: gap, mainAxisSpacing: gap),
                itemCount: itemCount, itemBuilder: itemBuilder,
              );
            }
            return MediaShelf(
              orientation: landscape ? Orientation.landscape : Orientation.portrait,
              cardHeight: artworkHeight + captionHeight,
              cardWidth: width,
              spacing: 8,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: math.min(itemCount, 6),
              itemBuilder: itemBuilder,
            );
          },
        ),
      const SizedBox(height: 2),
    ],
  );

  Widget _libraryShelf(CollectionSection title, List<LibraryTitle> titles) => _shelf(
    title,
    titles.length,
    itemCount: titles.length,
    itemBuilder: (_, index) => LibraryPosterCard(title: titles[index]),
  );

  Widget _historyShelf(CollectionSection title, List<CollectionHistoryEntry> entries) =>
      _shelf(
        title,
        _loading ? null : entries.length,
        itemCount: _loading ? 5 : entries.length,
        landscape: true,
        itemBuilder: (context, index) {
          if (_loading) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: MediaCard(
                  orientation: Orientation.landscape,
                  isLoading: true,
                )),
                SizedBox(height: 38),
              ],
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
