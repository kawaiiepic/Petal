import 'package:petal/api/api_cache.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/trakt/trakt_next_up.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class CatalogWidget extends StatefulWidget {
  const CatalogWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CatalogWidget();
}

class _CatalogWidget extends State<CatalogWidget> {
  final GlobalKey<RefreshTriggerState> _refreshTriggerKey = GlobalKey<RefreshTriggerState>();

  @override
  Widget build(BuildContext context) {
    return RefreshTrigger(
      key: _refreshTriggerKey,
      // Called when the user pulls down far enough or when we call .refresh().
      // Here we simulate a network call with a short delay.
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
      },
      
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(children: const [TraktNextUp(key: ValueKey("traktNextUp"))]),
          ),

          FutureBuilder(
            future: ApiCache.getAddons(),
            builder: (context, addonsSnapshot) {
              final addons = addonsSnapshot.data?.where((addon) => addon.enabledResources.contains("catalog"));

              final catalogs = addons?.expand((addon) => ApiCache.getCatalogs(addon)).toList();

              return SliverFixedExtentList(
                itemExtent: Device.screenType == ScreenType.desktop ? 25.h : 28.h,
                delegate: SliverChildBuilderDelegate((context, index) {
                  final catalog = catalogs?[index];

                  if (addonsSnapshot.hasData) {
                    return FutureBuilder(
                      future: ApiCache.getCatalogItems(catalog!),
                      builder: (context, snapshot) {
                        return CatalogRow(key: ValueKey(catalog.id), catalog: catalog, catalogItems: snapshot.data).asSkeleton(snapshot: snapshot);
                      },
                    );
                  } else {
                    return const CatalogRow(catalog: null, catalogItems: null).asSkeleton(snapshot: addonsSnapshot);
                  }
                }, childCount: addonsSnapshot.hasData ? catalogs?.length : 4),
              );
            },
          ),
        ],
      ),
    );
  }
}
