import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/pages/collection.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionHome extends StatefulWidget {
  const CollectionHome({super.key});

  @override
  State<CollectionHome> createState() => _CollectionHomeState();
}

class _CollectionHomeState extends State<CollectionHome> {
  final Set<String> _open = {'watching', 'watchlist'};

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
    return ValueListenableBuilder(
      valueListenable: BackendCache.watchHistory,
      builder: (context, history, _) {
        return ValueListenableBuilder(
          valueListenable: UserLibrary.watchlist,
          builder: (context, _, __) {
            return ValueListenableBuilder(
              valueListenable: UserLibrary.ratings,
              builder: (context, _, __) {
                final latest = <int, WatchHistoryItem>{};
                for (final item in history) {
                  final existing = latest[item.tmdbId];
                  if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
                    latest[item.tmdbId] = item;
                  }
                }
                final items = latest.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                final watching = items.where(isWatching).toList();
                final watched = items.where((i) => isFinished(i)).toList();
                final planned = items.where(isPlanned).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                  children: [
                    _section(context, id: 'watching', title: 'Watching', count: watching.length, child: _historyRow(watching, CollectionStatus.watching)),
                    _section(context, id: 'watchlist', title: 'Watchlist', count: UserLibrary.watchlistTitles().length, child: _libraryRow(UserLibrary.watchlistTitles())),
                    _section(context, id: 'liked', title: 'Liked', count: UserLibrary.ratedTitles().length, child: _libraryRow(UserLibrary.ratedTitles())),
                    _section(context, id: 'watched', title: 'Watched', count: watched.length, child: _historyRow(watched, CollectionStatus.watched)),
                    _section(context, id: 'planned', title: 'Planned', count: planned.length, child: _historyRow(planned, CollectionStatus.planned)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _section(BuildContext context, {required String id, required String title, required int count, required Widget child}) {
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
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text('$count', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(width: 8),
                Icon(open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18),
              ],
            ),
          ),
        ),
        if (open) child,
      ],
    );
  }

  Widget _historyRow(List<WatchHistoryItem> items, CollectionStatus status) {
    if (items.isEmpty) return const _EmptyRow(text: 'Nothing here yet');
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final isShow = item.mediaType == MediaType.show;
          return SizedBox(
            width: 118,
            child: FutureBuilder(
              future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Avatar(initials: '', borderRadius: 12).asSkeleton();
                final posterPath = (snapshot.data as dynamic).posterPath as String?;
                if (posterPath == null || posterPath.isEmpty) return const SizedBox.shrink();
                return CollectionCard(
                  item: item,
                  tmdb: snapshot.data,
                  status: status,
                  poster: HoverableItem(
                    image: CachedNetworkImage(imageUrl: Api.proxyImage('https://image.tmdb.org/t/p/w342$posterPath'), fit: BoxFit.cover),
                    onTap: () => context.push(isShow ? '/series?tmdb=${item.tmdbId}' : '/movie?tmdb=${item.tmdbId}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _libraryRow(List<LibraryTitle> titles) {
    if (titles.isEmpty) return const _EmptyRow(text: 'Nothing here yet');
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        scrollDirection: Axis.horizontal,
        itemCount: titles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(width: 118, child: LibraryPosterCard(title: titles[index])),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
    );
  }
}
