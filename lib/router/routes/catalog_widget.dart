import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/pages/catalog_row.dart';
import 'package:blssmpetal/pages/empty_sliver.dart';
import 'package:blssmpetal/pages/trakt_widget.dart';
import 'package:flutter/material.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      NextUpRow(),
      FutureBuilder(
        future: ApiCache.getAddons(),
        builder: (context, addonsSnapshot) {
          switch (addonsSnapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.done:
              {

                final addons = addonsSnapshot.data!.where((addon) => addon.enabledResources.contains("catalog"));

                final catalogs = addons.expand((addon) => ApiCache.getCatalogs(addon)).toList();

                return SliverFixedExtentList(
                  itemExtent: 300,
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final catalog = catalogs[index];

                    return FutureBuilder(
                      future: ApiCache.getCatalogItems(catalog),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.active:
                          case ConnectionState.done:
                            {
                              return CatalogRow(key: ValueKey(catalog.id), catalog: catalog, catalogItems: snapshot.data!);
                            }
                          case _:
                            return SizedBox();
                        }
                      },
                    );
                  }, childCount: catalogs.length),
                );
              }
            case _:
              return EmptySliver();
          }
        },
      ),
    ],
  );
}
