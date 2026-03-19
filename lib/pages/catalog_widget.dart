import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/pages/catalog_row.dart';
import 'package:flutter/material.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: ApiCache.getAddons(),
    builder: (context, addonsSnapshot) {
      switch (addonsSnapshot.connectionState) {
        case ConnectionState.active:
        case ConnectionState.done:
          {
            final addons = addonsSnapshot.data!.where((addon) => addon.enabledResources.contains("catalog"));
            print("Reloading Catalog Widget");
            return SliverFixedExtentList(
              itemExtent: 50,
              delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                final addon = addons.elementAt(index);
                return Text('${addon.name}');
              }, childCount: addons.length),
            );
            // return Column(
            //   children: [
            //     ...addons.map((addon) {
            //       return Column(
            //         children: [
            //           ...ApiCache.getCatalogs(addon).map((catalog) {
            //             return FutureBuilder(
            //               future: ApiCache.getCatalogItems(catalog),
            //               builder: (context, catalogItemsSnapshot) {
            //                 switch (catalogItemsSnapshot.connectionState) {
            //                   case ConnectionState.active:
            //                   case ConnectionState.done:
            //                     {
            //                       final catalogItems = catalogItemsSnapshot.data!;

            //                       return CatalogRow(catalog: catalog, catalogItems: catalogItems);
            //                     }
            //                   case _:
            //                     return SizedBox();
            //                 }
            //               },
            //             );
            //           }),
            //         ],
            //       );
            //     }),
            //   ],
            // );
          }
        case _:
          return SliverToBoxAdapter(
      child: SizedBox(height: 50.0), // Adjust height for desired gap size
    );
      }
    },
  );
}
