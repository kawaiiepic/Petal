import 'package:go_router/go_router.dart';
import 'package:petal/api/home_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/exceptions/connection_exception.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/catalog/catalog_section.dart';
import 'package:petal/widgets/connection_error_view.dart';
import 'package:petal/widgets/dashboard_stats.dart';
import 'package:petal/widgets/downloads/downloads_shelf.dart';
import 'package:petal/widgets/friend_activity.dart';
import 'package:petal/widgets/home/because_you_watched_shelf.dart';
import 'package:petal/widgets/home/liked_shelf.dart';
import 'package:petal/widgets/home/on_deck_shelf.dart';
import 'package:petal/widgets/home/recent_and_stalled_shelves.dart';
import 'package:petal/widgets/home/start_now_shelf.dart';
import 'package:petal/widgets/home/surprise_watchlist_button.dart';
import 'package:petal/widgets/home/watchlist_shelf.dart';
import 'package:petal/widgets/release_calendar.dart';
import 'package:petal/widgets/upcoming_episodes.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Catalog>> _catalogs;

  @override
  void initState() {
    super.initState();
    HomeLayout.instance.load();
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

    if (catalogs.isEmpty &&
        catalogAddons > 0 &&
        failedAddons == catalogAddons) {
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

        final catalogSlivers = <Widget>[
          if (loading && catalogs.isEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    const CatalogRow(catalog: null, catalogItems: null),
                childCount: 3,
              ),
            )
          else if (!loading && catalogs.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No shows to browse yet. Add a catalog addon to fill this page.',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                for (final catalog in catalogs)
                  CatalogSection(
                    key: ValueKey('${catalog.id}-${catalog.type}'),
                    catalog: catalog,
                  ),
              ], addAutomaticKeepAlives: true),
            ),
        ];
        final sections = <String, Widget>{
          'surprise': const SurpriseWatchlistButton(),
          'stats': const DashboardStats(),
          'upcoming': const UpcomingEpisodes(),
          'deck': const OnDeckShelf(),
          'start': const StartNowShelf(),
          'watchlist': const WatchlistShelf(),
          'liked': const LikedShelf(),
          'recent': const RecentAndStalledShelves(section: 'recent'),
          'stalled': const RecentAndStalledShelves(section: 'stalled'),
          'rewatched': const RecentAndStalledShelves(section: 'rewatched'),
          'because': const BecauseYouWatchedShelf(),
          'downloads': const DownloadsShelf(),
          'friends': const FriendActivity(),
          'calendar': const ReleaseCalendar(),
        };
        return ListenableBuilder(
          listenable: HomeLayout.instance,
          builder: (context, _) => CustomScrollView(
            scrollCacheExtent: ScrollCacheExtent.pixels(200),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Button.ghost(
                    onPressed: () => context.push('/home-layout'),
                    child: const Text('Customize Home'),
                  ),
                ),
              ),
              for (final id in HomeLayout.instance.order.where(
                (id) => !HomeLayout.instance.hidden.contains(id),
              ))
                if (id == 'catalogs')
                  ...catalogSlivers
                else
                  SliverToBoxAdapter(
                    key: ValueKey('home-$id'),
                    child: sections[id]!,
                  ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}
