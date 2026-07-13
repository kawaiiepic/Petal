import 'package:petal/api/api_cache.dart';
import 'package:petal/api/trakt/trakt_helper.dart';
import 'package:petal/pages/catalog_row.dart';
import 'package:petal/pages/empty_sliver.dart';
import 'package:petal/pages/trakt_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (TraktApi.authState.traktConnected) NextUpRow(),
            FutureBuilder(
              future: ApiCache.getAddons(),
              builder: (context, addonsSnapshot) {
                switch (addonsSnapshot.connectionState) {
                  case ConnectionState.active:
                  case ConnectionState.done:
                    {
                      final addons = addonsSnapshot.data!.where((addon) => addon.enabledResources.contains("catalog"));
                      // final addons = addonsSnapshot.data!.where((addon) => addon.id == "7a7eb1e6-c9fd-483b-b2e6-459549393c22");

                      final catalogs = addons.expand((addon) => ApiCache.getCatalogs(addon)).toList();

                      return SliverFixedExtentList(
                        itemExtent: 28.h,
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
        ),
      ),
    );
  }
}
