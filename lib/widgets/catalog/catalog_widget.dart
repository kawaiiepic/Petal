import 'package:petal/api/api_cache.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/connection_error.dart';
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ConnectionErrorView(
              error: snapshot.error,
              title: "Couldn't load ${catalog.name}",
            ),
          );
        }
        return CatalogRow(key: ValueKey('${catalog.id}-${catalog.type}'), catalog: catalog, catalogItems: snapshot.data);
      },
    );
  }
}
