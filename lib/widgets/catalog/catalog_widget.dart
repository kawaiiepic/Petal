import 'package:petal/api/api_cache.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/trakt/trakt_next_up.dart';
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

  Future<List<Catalog>> _loadCatalogs() async {
    final addons = await ApiCache.getAddons();
    final catalogs = <Catalog>[];
    for (final addon in addons) {
      if (!addon.enabledResources.contains('catalog')) continue;
      catalogs.addAll(await _catalogsFor(addon));
    }
    return catalogs;
  }

  Future<List<Catalog>> _catalogsFor(Addon addon) async {
    try {
      if (addon.manifest == null) await addon.fetchManifest();
      if (addon.manifest == null) return const [];
      return ApiCache.getCatalogs(addon);
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Catalog>>(
      future: _catalogs,
      builder: (context, snapshot) {
        final catalogs = snapshot.data ?? const <Catalog>[];
        final loading = snapshot.connectionState != ConnectionState.done;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: TraktNextUp(key: ValueKey('traktNextUp'))),
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _CatalogSection(catalog: catalogs[index]);
                }, childCount: catalogs.length),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}

class _CatalogSection extends StatelessWidget {
  final Catalog catalog;

  const _CatalogSection({required this.catalog});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CatalogItem>>(
      future: ApiCache.getCatalogItems(catalog),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return CatalogRow(catalog: catalog, catalogItems: const []);
        }
        return CatalogRow(key: ValueKey('${catalog.id}-${catalog.type}'), catalog: catalog, catalogItems: snapshot.data);
      },
    );
  }
}
