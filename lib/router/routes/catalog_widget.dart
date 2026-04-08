import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/catalog_row.dart';
import 'package:blssmpetal/pages/empty_sliver.dart';
import 'package:flutter/material.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  late final Future<List<CatalogWithItems>> _catalogsFuture;

  @override
  void initState() {
    super.initState();
    _catalogsFuture = _loadAllCatalogs();
  }

  Future<List<CatalogWithItems>> _loadAllCatalogs() async {
    final addons = await ApiCache.getAddons();
    final catalogs = addons.where((addon) => addon.enabledResources.contains("catalog")).expand((addon) => ApiCache.getCatalogs(addon)).toList();

    final results = await Future.wait(
      catalogs.map((catalog) async {
        final items = await ApiCache.getCatalogItems(catalog);
        return CatalogWithItems(catalog: catalog, items: items.take(3).toList());
      }),
    );

    // Prefetch all TMDB searches before rendering anything
    final allItems = results.expand((c) => c.items).toList();
    Future.wait(allItems.map((item) => ApiCache.getTmdbSearch(item.id)));

    return results;
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      FutureBuilder<List<CatalogWithItems>>(
        future: _catalogsFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SliverFixedExtentList(
                itemExtent: 300,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = snapshot.data![index];
                  return CatalogRow(key: ValueKey(entry.catalog.id), catalog: entry.catalog, catalogItems: entry.items);
                }, childCount: snapshot.data!.length),
              );
            case ConnectionState.waiting:
              return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
            default:
              return EmptySliver();
          }
        },
      ),
    ],
  );
}

class CatalogWithItems {
  final Catalog catalog;
  final List<CatalogItem> items;
  const CatalogWithItems({required this.catalog, required this.items});
}
