import 'package:go_router/go_router.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/social_api.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/connection_error.dart';
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FutureBuilder<List<SocialProfile>>(
                  future: _profiles,
                  builder: (context, profileSnap) {
                    final profiles = profileSnap.data ?? const <SocialProfile>[];
                    if (profiles.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Profiles', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          for (final profile in profiles)
                            Button.ghost(
                              alignment: Alignment.centerLeft,
                              onPressed: () => context.push('/profile/${profile.id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(profile.name),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('No results found.')))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _columns(context),
                      childAspectRatio: 2 / 3.15,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => CatalogItemWidget(catalogItem: items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
