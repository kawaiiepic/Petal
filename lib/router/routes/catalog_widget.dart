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
    return CustomScrollView(
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

                  final catalogs = addons.expand((addon) => ApiCache.getCatalogs(addon)).toList();

                  return SliverFixedExtentList(
                    itemExtent: Device.screenType == ScreenType.desktop ? 25.h : 28.h,
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
}
