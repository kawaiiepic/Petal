import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/connection_error.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<CatalogItem>> _future;
  late Future<List<SocialProfile>> _profiles;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.query);
    _profiles = SocialApi.searchProfiles(widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = _load(widget.query);
      _profiles = SocialApi.searchProfiles(widget.query);
    });
  }

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

  int _columns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 3;
    if (width < 700) return 4;
    if (width < 1100) return 5;
    return 6;
  }

  Widget _grid(List<CatalogItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns(context),
          childAspectRatio: 0.52,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => CatalogItemWidget(catalogItem: items[index], showTitle: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          leading: [BackButton()],
          title: Text(widget.query.trim().isEmpty ? 'Search' : widget.query.trim()),
        ),
      ],
      child: FutureBuilder<List<CatalogItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ConnectionErrorView(error: snapshot.error, onRetry: _reload);
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          final series = items.where((i) => i.type == 'series').toList();
          final movies = items.where((i) => i.type == 'movie').toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FutureBuilder<List<SocialProfile>>(
                  future: _profiles,
                  builder: (context, profileSnap) {
                    final profiles = profileSnap.data ?? const <SocialProfile>[];
                    if (profiles.isEmpty) return const SizedBox.shrink();
                    return HomeSection(
                      title: 'Profiles',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Column(
                          children: [
                            for (final profile in profiles) _ProfileResultRow(profile: profile),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (series.isNotEmpty)
                SliverToBoxAdapter(
                  child: HomeSection(title: 'Series', child: _grid(series)),
                ),
              if (movies.isNotEmpty)
                SliverToBoxAdapter(
                  child: HomeSection(title: 'Movies', child: _grid(movies)),
                ),
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: FutureBuilder<List<SocialProfile>>(
                    future: _profiles,
                    builder: (context, profileSnap) {
                      if (profileSnap.connectionState != ConnectionState.done) return const SizedBox.shrink();
                      if ((profileSnap.data ?? const <SocialProfile>[]).isNotEmpty) return const SizedBox.shrink();
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('No results found.')),
                      );
                    },
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileResultRow extends StatelessWidget {
  final SocialProfile profile;

  const _ProfileResultRow({required this.profile});

  String? get _avatarUrl {
    final avatar = profile.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http')) return avatar;
    return '${Api.ProfileUrl}/$avatar';
  }

  @override
  Widget build(BuildContext context) {
    final initials = profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?';
    final url = _avatarUrl;

    final avatar = url == null
        ? Avatar(initials: initials, size: 36)
        : CachedNetworkImage(
            imageUrl: url,
            imageBuilder: (context, provider) => Avatar(initials: initials, provider: provider, size: 36),
            placeholder: (context, _) => Avatar(initials: initials, size: 36),
            errorWidget: (context, _, _) => Avatar(initials: initials, size: 36),
          );

    return Button.ghost(
      alignment: Alignment.centerLeft,
      onPressed: () => context.push('/profile/${profile.id}'),
      leading: avatar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(profile.name),
      ),
    );
  }
}
