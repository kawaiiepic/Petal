import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/rendering.dart' show SystemMouseCursors;
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:petal/models/tmdb/person_search_result.dart';
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

enum _ResultFilter { all, movies, series, actors, profiles }

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late String _query;
  late Future<List<CatalogItem>> _future;
  late Future<List<SocialProfile>> _profiles;
  late Future<List<PersonSearchResult>> _actors;
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
    _query = widget.query;
    _future = _load(_query);
    _profiles = _loadProfiles();
    _actors = _loadActors();
  }

  @override
  void didUpdateWidget(covariant SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _query != widget.query) {
      _setQuery(widget.query);
    }
  }

  void _setQuery(String value) {
    final next = value.trim();
    if (next == _query) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _query = next;
      _future = _load(_query);
      _profiles = _loadProfiles();
      _actors = _loadActors();
    });
  }

  void _changeQuery(String value) {
    _setQuery(value);
    final route = Uri(path: '/search', queryParameters: value.isEmpty ? null : {'q': value});
    if (GoRouter.of(context).state.uri != route) context.go(route.toString());
  }

  void _reload() {
    setState(() {
      _future = _load(_query);
      _profiles = _loadProfiles();
      _actors = _loadActors();
    });
  }

  Future<List<PersonSearchResult>> _loadActors() async {
    final query = _query.trim();
    if (query.isEmpty) return [];
    // The proxy decodes the supplied path once before sending it to TMDB.
    final encoded = Uri.encodeQueryComponent(Uri.encodeQueryComponent(query));
    final response = await TMDB.tmdbApi('/search/person?query=$encoded&include_adult=false');
    if (response.statusCode != 200) throw StateError('Actor search failed');
    final rows = (response.data as Map)['results'] as List? ?? [];
    final seen = <int>{};
    return [
      for (final row in rows.whereType<Map>())
        if (row['id'] is int && row['name'] is String &&
            row['known_for_department'] == 'Acting' && seen.add(row['id'] as int))
          PersonSearchResult.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  Future<List<SocialProfile>> _loadProfiles() => _query.trim().isEmpty
      ? Future.value(const [])
      : SocialApi.searchProfiles(_query);

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
      _ResultFilter.actors: 'Actors',
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
    final heading = Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
      Flexible(child: Text(title, style: TextStyle(fontSize: 20,
        color: colors.foreground, fontWeight: FontWeight.w700))),
      if (count != null) SecondaryBadge(child: Text('$count')),
      if (more != null) Icon(LucideIcons.chevronRight, size: 16,
        color: colors.mutedForeground),
    ]);
    void open() { if (more != null) _select(more); }
    return SliverToBoxAdapter(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Align(alignment: Alignment.centerLeft,
        child: more == null ? heading : Semantics(button: true,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              open(); return null;
            })},
            child: GestureDetector(behavior: HitTestBehavior.opaque,
              onTap: open, child: heading),
          ),
        ),
      ),
    ));
  }

  Widget _actorGrid(List<PersonSearchResult> actors) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverLayoutBuilder(builder: (context, constraints) {
      final columns = (constraints.crossAxisExtent / 120).floor().clamp(2, 10).toInt();
      final width = (constraints.crossAxisExtent - (columns - 1) * 12) / columns;
      return SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 16,
          mainAxisExtent: width + 44),
        itemCount: actors.length,
        itemBuilder: (context, index) {
          final actor = actors[index];
          final colors = Theme.of(context).colorScheme;
          return Semantics(button: true, label: actor.name,
            child: MouseRegion(cursor: SystemMouseCursors.click,
              child: GestureDetector(behavior: HitTestBehavior.opaque,
                onTap: () => context.push('/person/${actor.id}'),
                child: Column(children: [
                  Expanded(child: AspectRatio(aspectRatio: 1,
                    child: ClipOval(child: actor.profilePath == null
                      ? ColoredBox(color: colors.muted,
                        child: Center(child: Icon(LucideIcons.user, size: 32,
                          color: colors.mutedForeground)))
                      : MediaArtwork(imageUrl: Api.proxyImage(
                        'https://image.tmdb.org/t/p/w185${actor.profilePath}'))))),
                  const SizedBox(height: 6),
                  Text(actor.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(actor.knownFor, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colors.mutedForeground)),
                ]),
              ),
            ),
          );
        },
      );
    }),
  );

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
    if (_query.trim().isEmpty) return const SearchDiscovery();
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
          Row(children: [
            const Expanded(child: Text('Search',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800))),
            PetalButton.ghost(onPressed: () => _changeQuery(''),
              child: Text('Browse', style: TextStyle(color: colors.foreground))),
          ]),
          SearchField(initialQuery: _query, onQueryChanged: _changeQuery,
            replaceResults: true, placeholder: 'Shows, Movies, Actors, and More'),
        ]),
      )),
      _filterBar(),
      Expanded(child: FutureBuilder<List<CatalogItem>>(
        future: _future,
        builder: (context, mediaSnap) => FutureBuilder<List<SocialProfile>>(
          future: _profiles,
          builder: (context, profileSnap) => FutureBuilder<List<PersonSearchResult>>(
            future: _actors,
            builder: (context, actorSnap) {
            final mediaLoading = mediaSnap.connectionState != ConnectionState.done;
            final profilesLoading = profileSnap.connectionState != ConnectionState.done;
            final items = mediaLoading ? const <CatalogItem>[] : mediaSnap.data ?? const <CatalogItem>[];
            final profiles = profilesLoading ? const <SocialProfile>[] : profileSnap.data ?? const <SocialProfile>[];
            final movies = items.where((i) => i.type == 'movie').toList();
            final series = items.where((i) => i.type == 'series').toList();
            final all = _filter == _ResultFilter.all;
            final peopleOnly = _filter == _ResultFilter.profiles;
            final actorsOnly = _filter == _ResultFilter.actors;
            final actorsLoading = actorSnap.connectionState != ConnectionState.done;
            final actors = actorsLoading ? const <PersonSearchResult>[] : actorSnap.data ?? const <PersonSearchResult>[];
            final filtered = _filter == _ResultFilter.movies ? movies :
                _filter == _ResultFilter.series ? series : items;
            final slivers = <Widget>[];
            if (!peopleOnly && !actorsOnly) {
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
            if (all || actorsOnly) {
              if (actorsLoading) {
                if (actorsOnly) slivers.add(const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(32), child: Center(child: PetalActivityIndicator()))));
              } else if (actorSnap.hasError) {
                if (actorsOnly) slivers.add(_message(LucideIcons.user, 'Could not load actors',
                  'Please try again.', retry: _reload));
              } else if (actors.isNotEmpty) {
                slivers.addAll([
                  _heading('Actors', count: actors.length, more: all ? _ResultFilter.actors : null),
                  _actorGrid(all ? actors.take(6).toList() : actors),
                ]);
              } else if (actorsOnly) {
                slivers.add(_message(LucideIcons.user, 'No actors found', 'Try another actor name.'));
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
                    more: all ? _ResultFilter.profiles : null),
                  _profileRows(all ? profiles.take(4).toList() : profiles),
                ]);
              } else if (peopleOnly) {
                slivers.add(_message(LucideIcons.users, 'No profiles found', 'Try another profile name.'));
              }
            }
            if (all && !mediaLoading && !profilesLoading && !actorsLoading && items.isEmpty && profiles.isEmpty && actors.isEmpty &&
                !mediaSnap.hasError && !profileSnap.hasError && !actorSnap.hasError) {
              slivers.add(_message(LucideIcons.search, 'No results found',
                'No movies, shows, actors or profiles match “${_query}”.'));
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
        ),
      )),
    ]);
  }
}
