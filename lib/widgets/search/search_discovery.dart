import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/widgets/search/search_field.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

/// Browse the titles available from the user's addons before entering a query.
class SearchDiscovery extends StatefulWidget {
  const SearchDiscovery({super.key, this.onSearch});

  final ValueChanged<String>? onSearch;

  @override
  State<SearchDiscovery> createState() => _SearchDiscoveryState();
}

class _SearchDiscoveryState extends State<SearchDiscovery> {
  late final _groups = _loadGroups();
  final _scroll = ScrollController();
  String? _selected;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String? name) {
    _scroll.jumpTo(0);
    setState(() => _selected = name);
  }

  Future<Map<String, List<CatalogItem>>> _loadGroups() async {
    final items = <String, CatalogItem>{};
    try {
      final addons = await ApiCache.getAddons();
      final catalogs = addons
          .where(
            (addon) =>
                addon.enabledResources.contains('catalog') &&
                addon.manifest != null,
          )
          .expand(ApiCache.getCatalogs)
          .take(6);
      final results = await Future.wait(
        catalogs.map((catalog) async {
          try {
            return await ApiCache.getCatalogItems(catalog);
          } catch (_) {
            return const <CatalogItem>[];
          }
        }),
      );
      for (final item in results.expand((items) => items)) {
        if (item.type == 'movie' || item.type == 'series') {
          items.putIfAbsent('${item.type}:${item.id}', () => item);
        }
      }
    } catch (_) {
      // The regular search field still works without catalog browse data.
    }
    final media = <String, List<CatalogItem>>{'Movies': [], 'TV Shows': []};
    final genres = <String, List<CatalogItem>>{};
    for (final item in items.values) {
      media[item.type == 'movie' ? 'Movies' : 'TV Shows']!.add(item);
      for (final genre in item.genres.map((g) => g.trim()).toSet()) {
        if (genre.isEmpty || media.containsKey(genre)) continue;
        (genres[genre] ??= []).add(item);
      }
    }
    final popular = genres.entries.toList()
      ..sort((a, b) {
        final count = b.value.length.compareTo(a.value.length);
        return count == 0 ? a.key.compareTo(b.key) : count;
      });
    return {
      for (final entry in media.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
      for (final entry in popular.take(13)) entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screen = TvLayout.of(context);
    final compact = screen != ScreenType.desktop;
    final bottom = compact
        ? IosNavigationDock.clearance + MediaQuery.viewPaddingOf(context).bottom
        : 24.0;
    final columns = screen == ScreenType.tablet ? 5 : 3;
    return FutureBuilder<Map<String, List<CatalogItem>>>(
      future: _groups,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const {};
        final names = groups.keys.toList();
        final selected = groups[_selected];
        return CustomScrollView(
          primary: false,
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SearchField(placeholder: 'Shows, Movies, Actors, and More',
                        onSubmitted: widget.onSearch),
                    ],
                  ),
                ),
              ),
            ),
            if (selected != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      PetalButton.ghost(
                        onPressed: () => _select(null),
                        child: const Text('All categories'),
                      ),
                    ],
                  ),
                ),
              ),
            if (snapshot.connectionState != ConnectionState.done)
              const SliverToBoxAdapter(
                child: Center(child: PetalActivityIndicator()),
              )
            else if (names.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Browse categories appear when your addons provide catalog titles.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.builder(
                  gridDelegate: compact
                      ? SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2 / 3,
                        )
                      : const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 184,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 2 / 3,
                        ),
                  itemCount: selected?.length ?? names.length,
                  itemBuilder: (context, index) {
                    if (selected != null)
                      return CatalogItemWidget(catalogItem: selected[index]);
                    final name = names[index];
                    return _tile(name, groups[name]!, index);
                  },
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: bottom)),
          ],
        );
      },
    );
  }

  Widget _tile(String name, List<CatalogItem> items, int index) {
    const colors = [
      Color(0xFF1E536B),
      Color(0xFF73402D),
      Color(0xFF453077),
      Color(0xFF285C52),
      Color(0xFF7E3256),
      Color(0xFF254677),
    ];
    final tint = colors[index % colors.length];
    final poster = items
        .where((item) => item.poster.isNotEmpty)
        .firstOrNull
        ?.poster;
    return Semantics(
      button: true,
      child: HoverableItem(
        onTap: () => _select(name),
        image: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: tint),
            if (poster != null) MediaArtwork(imageUrl: Api.proxyImage(poster)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tint.withValues(alpha: .24),
                    tint.withValues(alpha: .5),
                    const Color(0xED0C0C11),
                  ],
                  stops: const [0, .62, 1],
                ),
              ),
            ),
          ],
        ),
        extraWidget: Positioned(
          left: 9,
          bottom: 10,
          right: 8,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
