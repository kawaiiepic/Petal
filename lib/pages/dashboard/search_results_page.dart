import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:go_router/go_router.dart';
import 'package:petal/api/retained_player.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/stream_api.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/social/social_profile.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:petal/widgets/search/search_discovery.dart';
import 'package:petal/widgets/search/search_field.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/search/profile_result_row.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum _ResultFilter { all, movies, series, profiles }

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<CatalogItem>> _future;
  late Future<List<SocialProfile>> _profiles;
  final _scroll = ScrollController();
  _ResultFilter _filter = _ResultFilter.all;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _future = _load(widget.query);
    _profiles = _loadProfiles();
  }

  @override
  void didUpdateWidget(covariant SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _filter = _ResultFilter.all;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = _load(widget.query);
      _profiles = _loadProfiles();
    });
  }

  Future<List<SocialProfile>> _loadProfiles() => widget.query.trim().isEmpty
      ? Future.value(const [])
      : SocialApi.searchProfiles(widget.query);

  Future<List<CatalogItem>> _load(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final addons = await ApiCache.getAddons();
    final raw = await StreamApi.searchCatalogItems(trimmed, addons);

    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final item in raw) {
      if (item.type != 'movie' && item.type != 'series') continue;
      if (!seen.add('${item.type}:${item.id}')) continue;
      items.add(item);
    }
    return items;
  }

  void _select(_ResultFilter filter) {
    if (_filter == filter) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() => _filter = filter);
  }

  Widget _filterBar() {
    final colors = Theme.of(context).colorScheme;
    const labels = {
      _ResultFilter.all: 'All',
      _ResultFilter.movies: 'Movies',
      _ResultFilter.series: 'TV Shows',
      _ResultFilter.profiles: 'Profiles',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(spacing: 8, children: [
        for (final entry in labels.entries)
          glass.GlassButton.custom(
            label: entry.value, height: 36, useOwnLayer: true,
            isSelected: _filter == entry.key,
            shape: const glass.LiquidRoundedSuperellipse(borderRadius: 18),
            style: _filter == entry.key ? glass.GlassButtonStyle.prominent :
              glass.GlassButtonStyle.filled,
            tintColor: _filter == entry.key ? colors.primary : null,
            onTap: () => _select(entry.key),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(entry.value, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: _filter == entry.key ? colors.primaryForeground : colors.foreground))),
          ),
      ]),
    );
  }

  Widget _heading(String title, {int? count, _ResultFilter? more}) {
    final colors = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(children: [
        Expanded(child: Row(spacing: 9, children: [
          Container(width: 3, height: 19, decoration: BoxDecoration(
            color: colors.primary, borderRadius: BorderRadius.circular(2))),
          Flexible(child: Text(title, style: const TextStyle(fontSize: 20,
            fontWeight: FontWeight.w700))),
          if (count != null) Text('$count', style: TextStyle(fontSize: 12,
            color: colors.mutedForeground)),
        ])),
        if (more != null) PetalButton.ghost(
          onPressed: () => _select(more),
          child: Text('See all', style: TextStyle(fontSize: 12, color: colors.foreground))),
      ]),
    ));
  }

  Widget _card(CatalogItem? item, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meta = item == null ? '' : [
      if (item.year > 0) '${item.year}',
      item.type == 'movie' ? 'Movie' : 'TV Show',
    ].join(' · ');
    void open() {
      if (item == null) return;
      final type = item.type == 'movie' ? 'movie' : 'series';
      final key = int.tryParse(item.id) == null ? 'imdb' : 'tmdb';
      context.push('/$type?$key=${Uri.encodeQueryComponent(item.id)}');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: CatalogItemWidget(catalogItem: item)),
      const SizedBox(height: 6),
      if (item == null) ...[
        Container(height: 12, width: 74, decoration: BoxDecoration(
          color: colors.muted, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 5),
        Container(height: 10, width: 46, decoration: BoxDecoration(
          color: colors.muted, borderRadius: BorderRadius.circular(4))),
      ] else
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: open,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
          ])),
    ]);
  }

  Widget _grid(List<CatalogItem?> items) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverLayoutBuilder(builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      final compact = TvLayout.isCompact(context);
      final columns = compact
          ? (width / 105).floor().clamp(2, 5).toInt()
          : (width / 155).floor().clamp(3, 9).toInt();
      final gap = compact ? 10.0 : 16.0;
      final cardWidth = (width - gap * (columns - 1)) / columns;
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, crossAxisSpacing: gap, mainAxisSpacing: 16,
          mainAxisExtent: cardWidth * 4 / 3 + 43),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return KeyedSubtree(key: ValueKey(item == null ? 'loading:$index' :
            '${item.type}:${item.id}'), child: _card(item, context));
        },
      );
    }),
  );

  Widget _profileRows(List<SocialProfile> profiles) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverList.builder(itemCount: profiles.length,
      itemBuilder: (context, index) => ProfileResultRow(profile: profiles[index])),
  );

  Widget _message(IconData icon, String title, String description, {VoidCallback? retry}) {
    final colors = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(spacing: 10, children: [
        Icon(icon, size: 35, color: colors.mutedForeground),
        Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        Text(description, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: colors.mutedForeground)),
        if (retry != null) PetalButton.secondary(onPressed: retry, child: const Text('Try again')),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    if (widget.query.trim().isEmpty) return const SearchDiscovery();
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
          Row(children: [
            const Expanded(child: Text('Search',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800))),
            PetalButton.ghost(onPressed: () => context.replace('/search'),
              child: Text('Browse', style: TextStyle(color: colors.foreground))),
          ]),
          SearchField(key: ValueKey(widget.query), initialQuery: widget.query,
            replaceResults: true, placeholder: 'Shows, Movies, and More'),
        ]),
      )),
      _filterBar(),
      Expanded(child: FutureBuilder<List<CatalogItem>>(
        future: _future,
        builder: (context, mediaSnap) => FutureBuilder<List<SocialProfile>>(
          future: _profiles,
          builder: (context, profileSnap) {
            final mediaLoading = mediaSnap.connectionState != ConnectionState.done;
            final profilesLoading = profileSnap.connectionState != ConnectionState.done;
            final items = mediaLoading ? const <CatalogItem>[] : mediaSnap.data ?? const <CatalogItem>[];
            final profiles = profilesLoading ? const <SocialProfile>[] : profileSnap.data ?? const <SocialProfile>[];
            final movies = items.where((i) => i.type == 'movie').toList();
            final series = items.where((i) => i.type == 'series').toList();
            final all = _filter == _ResultFilter.all;
            final peopleOnly = _filter == _ResultFilter.profiles;
            final filtered = _filter == _ResultFilter.movies ? movies :
                _filter == _ResultFilter.series ? series : items;
            final slivers = <Widget>[];
            if (!peopleOnly) {
              if (mediaLoading) {
                slivers.addAll([_heading('Searching…'), _grid(List<CatalogItem?>.filled(12, null))]);
              } else if (mediaSnap.hasError) {
                slivers.add(_message(LucideIcons.search, 'Could not load titles',
                  'Check your connection or search addons.', retry: _reload));
              } else if (all) {
                // Preserve addon search order in the top results, then allow drilling into each type.
                if (items.isNotEmpty) slivers.addAll([
                  _heading('Top results', count: items.length),
                  _grid(items.take(6).toList()),
                ]);
                if (movies.isNotEmpty) slivers.addAll([
                  _heading('Movies', count: movies.length, more: _ResultFilter.movies),
                  _grid(movies.take(6).toList()),
                ]);
                if (series.isNotEmpty) slivers.addAll([
                  _heading('TV Shows', count: series.length, more: _ResultFilter.series),
                  _grid(series.take(6).toList()),
                ]);
              } else if (filtered.isNotEmpty) {
                slivers.addAll([
                  _heading(_filter == _ResultFilter.movies ? 'Movies' : 'TV Shows', count: filtered.length),
                  _grid(filtered),
                ]);
              } else {
                slivers.add(_message(LucideIcons.search, 'No matching titles',
                  'Try a different search or switch categories.'));
              }
            }
            if (all || peopleOnly) {
              if (profilesLoading) {
                if (peopleOnly) slivers.add(const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(32), child: Center(child: PetalActivityIndicator()))));
              } else if (profileSnap.hasError) {
                if (peopleOnly) slivers.add(_message(LucideIcons.users, 'Could not load profiles',
                  'Please try again.', retry: _reload));
              } else if (profiles.isNotEmpty) {
                slivers.addAll([
                  _heading('Profiles', count: profiles.length,
                    more: all && profiles.length > 4 ? _ResultFilter.profiles : null),
                  _profileRows(all ? profiles.take(4).toList() : profiles),
                ]);
              } else if (peopleOnly) {
                slivers.add(_message(LucideIcons.users, 'No profiles found', 'Try another profile name.'));
              }
            }
            if (all && !mediaLoading && !profilesLoading && items.isEmpty && profiles.isEmpty &&
                !mediaSnap.hasError && !profileSnap.hasError) {
              slivers.add(_message(LucideIcons.search, 'No results found',
                'No movies, shows or profiles match “${widget.query}”.'));
            }
            return ValueListenableBuilder(valueListenable: RetainedPlayer.instance.available,
              builder: (context, retained, _) => CustomScrollView(
                controller: _scroll, primary: false,
                slivers: [
                  ...slivers,
                  SliverToBoxAdapter(child: SizedBox(height: compact
                    ? IosNavigationDock.clearance + MediaQuery.viewPaddingOf(context).bottom +
                      (retained != null ? 64 : 0) : 24)),
                ],
              ));
          },
        ),
      )),
    ]);
  }
}
