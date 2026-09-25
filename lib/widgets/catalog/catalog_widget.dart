import 'package:petal/api/api_cache.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/connection_error.dart';
import 'package:petal/widgets/dashboard_stats.dart';
import 'package:petal/widgets/friend_activity.dart';
import 'package:petal/widgets/home_shelves.dart';
import 'package:petal/widgets/in_progress_shelf.dart';
import 'package:petal/widgets/release_calendar.dart';
import 'package:petal/widgets/upcoming_episodes.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  late Future<List<Catalog>> _catalogs;

  @override
  void initState() {
    super.initState();
    _catalogs = _loadCatalogs();
  }

  void _reload() {
    setState(() {
      _catalogs = _loadCatalogs();
    });
  }

  Future<List<Catalog>> _loadCatalogs() async {
    final addons = await ApiCache.getAddons();
    final catalogs = <Catalog>[];
    var catalogAddons = 0;
    var failedAddons = 0;

    for (final addon in addons) {
      if (!addon.enabledResources.contains('catalog')) continue;
      catalogAddons++;
      try {
        catalogs.addAll(await _catalogsFor(addon));
      } catch (_) {
        failedAddons++;
      }
    }

    if (catalogs.isEmpty && catalogAddons > 0 && failedAddons == catalogAddons) {
      throw const ConnectionException('Could not load catalogs.');
    }

    for (final catalog in catalogs) {
      ApiCache.getCatalogItems(catalog);
    }

    return catalogs;
  }

  Future<List<Catalog>> _catalogsFor(Addon addon) async {
    if (addon.manifest == null) await addon.fetchManifest();
    if (addon.manifest == null) {
      throw const ConnectionException('Addon manifest unavailable.');
    }
    return ApiCache.getCatalogs(addon);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Catalog>>(
      future: _catalogs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ConnectionErrorView(error: snapshot.error, onRetry: _reload);
        }

        final catalogs = snapshot.data ?? const <Catalog>[];
        final loading = snapshot.connectionState != ConnectionState.done;

        return CustomScrollView(
          cacheExtent: 2500,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: DashboardStats()),
            const SliverToBoxAdapter(child: SurpriseWatchlistButton()),
            const SliverToBoxAdapter(child: FriendActivity()),
            const SliverToBoxAdapter(child: UpcomingEpisodes()),
            const SliverToBoxAdapter(child: ReleaseCalendar()),
            const SliverToBoxAdapter(child: OnDeckShelf()),
            const SliverToBoxAdapter(child: StartNowShelf()),
            const SliverToBoxAdapter(child: InProgressShelf()),
            const SliverToBoxAdapter(child: WatchlistShelf()),
            const SliverToBoxAdapter(child: LikedShelf()),
            const SliverToBoxAdapter(child: RecentAndStalledShelves()),
            const SliverToBoxAdapter(child: BecauseYouWatchedShelf()),
            if (loading && catalogs.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const CatalogRow(catalog: null, catalogItems: null),
                  childCount: 3,
                ),
              )
            else if (!loading && catalogs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No shows to browse yet. Add a catalog addon to fill this page.'),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate(
                  [for (final catalog in catalogs) _CatalogSection(key: ValueKey('${catalog.id}-${catalog.type}'), catalog: catalog)],
                  addAutomaticKeepAlives: true,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}

class _CatalogSection extends StatefulWidget {
  final Catalog catalog;

  const _CatalogSection({super.key, required this.catalog});

  @override
  State<_CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends State<_CatalogSection> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<CatalogItem>>(
      future: ApiCache.getCatalogItems(widget.catalog),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ConnectionErrorView(
              error: snapshot.error,
              title: "Couldn't load ${widget.catalog.name}",
            ),
          );
        }
        return CatalogRow(catalog: widget.catalog, catalogItems: snapshot.data);
      },
    );
  }
}
