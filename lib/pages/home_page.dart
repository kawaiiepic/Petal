import 'dart:async';

import 'package:petal/api/upcoming_releases.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/widgets/home/home_shelf_skeleton.dart';
import 'package:petal/api/home_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/exceptions/connection_exception.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/catalog/catalog_section.dart';
import 'package:petal/widgets/connection_error_view.dart';
import 'package:petal/widgets/dashboard_stats.dart';
import 'package:petal/widgets/downloads/downloads_shelf.dart';
import 'package:petal/widgets/friend_activity.dart';
import 'package:petal/widgets/home/because_you_watched_shelf.dart';
import 'package:petal/widgets/home/continue_watching_shelf.dart';
import 'package:petal/widgets/home/desktop_featured_hero.dart';
import 'package:petal/widgets/home/home_quick_actions.dart';
import 'package:petal/widgets/home/ios_featured_hero.dart';
import 'package:petal/widgets/home/liked_shelf.dart';
import 'package:petal/widgets/home/on_deck_shelf.dart';
import 'package:petal/widgets/home/recent_and_stalled_shelves.dart';
import 'package:petal/widgets/home/start_now_shelf.dart';
import 'package:petal/widgets/home/watchlist_shelf.dart';
import 'package:petal/widgets/release_calendar.dart';
import 'package:petal/widgets/upcoming_episodes.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

import 'package:petal/navigation/ios_navigation_dock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late Future<List<Catalog>> _catalogs;
  Future<List<CatalogItem>>? _featured;
  late Future<void> _homeData;
  String? _profileKey;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_revalidate());
      }
    });
    HomeLayout.instance.load();
    _catalogs = _loadCatalogs();
    _profileKey = BackendApi.profileCacheKey;
    _homeData = _loadHomeData();
    BackendApi.authState.addListener(_onProfileChanged);
  }

  Future<void> _loadHomeData() async {
    if (BackendApi.profileCacheKey == null) return;
    await Future.wait([
      BackendCache.fetchWatchHistory().catchError((Object _) {}),
      BackendCache.fetchContinueWatching().catchError((Object _) {}),
      UserLibrary.load(),
    ]);
  }

  Future<void> _revalidate() async {
    if (BackendApi.profileCacheKey == null) return;
    try {
      await Future.wait([
        BackendCache.fetchWatchHistory(force: true),
        BackendCache.fetchContinueWatching(force: true),
        UserLibrary.load(force: true),
      ]);
      await UpcomingReleases.fetch();
    } catch (_) {
      // Retain visible snapshots while offline; retry on resume or the next tick.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_revalidate());
  }

  void _onProfileChanged() {
    final key = BackendApi.profileCacheKey;
    if (key == _profileKey) return;
    setState(() {
      _profileKey = key;
      _homeData = _loadHomeData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    BackendApi.authState.removeListener(_onProfileChanged);
    super.dispose();
  }

  Widget _placeholder(String id) {
    final landscape = {'upcoming', 'deck', 'start', 'recent', 'friends'};
    return HomeShelfSkeleton(
      title: switch (id) {
        'stats' => 'Stats',
        'watchlist' => 'From your watchlist',
        'deck' => 'On deck',
        'rewatched' => 'Most rewatched',
        _ => HomeLayout.labels[id]!,
      },
      orientation: landscape.contains(id) || id == 'stats'
          ? Orientation.landscape
          : Orientation.portrait,
      cardHeight: switch (id) {
        'stats' => 110,
        'friends' => 148,
        _ => 180,
      },
      editorial: id == 'stats' || id == 'upcoming' || id == 'friends',
    );
  }

  void _reload() {
    setState(() {
      _featured = null;
      _catalogs = _loadCatalogs();
      _homeData = _loadHomeData();
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
      ApiCache.getCatalogItems(catalog).ignore();
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

  Future<List<CatalogItem>> _loadFeatured(List<Catalog> catalogs) async {
    const pageLimit = 8;
    final backdrops = <String, CatalogItem>{};
    final posters = <String, CatalogItem>{};
    for (final catalog in catalogs) {
      try {
        for (final item in await ApiCache.getCatalogItems(catalog)) {
          if (item.type != 'movie' && item.type != 'series') continue;
          final id = int.tryParse(item.id);
          if ((id == null || id <= 0) && !RegExp(r'^tt\d+$').hasMatch(item.id))
            continue;
          final key = '${item.type}:${item.id}';
          if (item.background.isNotEmpty) {
            backdrops.putIfAbsent(key, () => item);
          } else if (item.poster.isNotEmpty) {
            posters.putIfAbsent(key, () => item);
          }
          if (backdrops.length >= pageLimit) break;
        }
      } catch (_) {
        // A failed catalog still gets its own retry/error UI in the browse row.
      }
      if (backdrops.length >= pageLimit) break;
    }
    return [
      ...backdrops.values,
      ...posters.entries
          .where((entry) => !backdrops.containsKey(entry.key))
          .map((entry) => entry.value),
    ].take(pageLimit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    return FutureBuilder<List<Catalog>>(
      future: _catalogs,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = ConnectionErrorView(
            error: snapshot.error,
            onRetry: _reload,
          );
          return compact
              ? Column(
                  children: [
                    const IosFeaturedHero(items: []),
                    Expanded(child: error),
                  ],
                )
              : error;
        }

        final catalogs = snapshot.data ?? const <Catalog>[];
        final loading = snapshot.connectionState != ConnectionState.done;
        final promoted = <String, Catalog>{};
        for (final catalog in catalogs) {
          if (catalog.id == 'top' &&
              {'series', 'movie'}.contains(catalog.type)) {
            promoted.putIfAbsent(catalog.type, () => catalog);
          }
        }

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
                  if (promoted[catalog.type]?.url != catalog.url)
                    CatalogSection(
                      key: ValueKey(catalog.url),
                      catalog: catalog,
                    ),
              ], addAutomaticKeepAlives: true),
            ),
        ];
        final sections = <String, Widget>{
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
        return FutureBuilder<void>(
          future: _homeData,
          builder: (context, data) {
            final loadingRows =
                _profileKey != null &&
                data.connectionState != ConnectionState.done;
            return ListenableBuilder(
              listenable: HomeLayout.instance,
              builder: (context, _) => CustomScrollView(
                primary: compact,
                scrollCacheExtent: ScrollCacheExtent.pixels(200),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<CatalogItem>>(
                      future:
                          catalogs.isNotEmpty &&
                              !HomeLayout.instance.hidden.contains('catalogs')
                          ? _featured ??= _loadFeatured(catalogs)
                          : null,
                      builder: (context, featured) {
                        final items =
                            featured.connectionState == ConnectionState.done
                            ? featured.data ?? const <CatalogItem>[]
                            : const <CatalogItem>[];
                        return compact
                            ? IosFeaturedHero(items: items)
                            : DesktopFeaturedHero(items: items);
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HomeQuickActions(
                      showSurprise: !HomeLayout.instance.hidden.contains(
                        'surprise',
                      ),
                    ),
                  ),
                  if (!HomeLayout.instance.hidden.contains('deck'))
                    const SliverToBoxAdapter(
                      child: ContinueWatchingShelf(editorial: true),
                    ),
                  if (!HomeLayout.instance.hidden.contains('catalogs'))
                    for (final catalog in promoted.values)
                      SliverToBoxAdapter(
                        key: ValueKey(catalog.url),
                        child: CatalogSection(catalog: catalog),
                      ),
                  for (final id in HomeLayout.instance.order.where(
                    (id) =>
                        id != 'surprise' &&
                        !HomeLayout.instance.hidden.contains(id),
                  ))
                    if (id == 'catalogs')
                      ...catalogSlivers
                    else
                      SliverToBoxAdapter(
                        key: ValueKey('home-$_profileKey-$id'),
                        child:
                            loadingRows &&
                                !{'downloads', 'calendar'}.contains(id)
                            ? _placeholder(id)
                            : sections[id]!,
                      ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: compact
                          ? IosNavigationDock.clearance +
                                MediaQuery.viewPaddingOf(context).bottom
                          : 32,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
