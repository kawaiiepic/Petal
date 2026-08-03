import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CatalogRow extends StatefulWidget {
  final Catalog? catalog;
  final List<CatalogItem>? catalogItems;

  const CatalogRow({super.key, required this.catalog, required this.catalogItems});

  @override
  State<StatefulWidget> createState() => _CatalogRowState();
}

class _CatalogRowState extends State<CatalogRow> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    final Catalog? catalog = widget.catalog;
    final List<CatalogItem>? catalogItems = widget.catalogItems?.toList();
    final style = TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp);

    return Column(
      spacing: 8,
      children: [
        Skeleton.keep(
          keep: catalog != null,
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(catalog?.name ?? 'Popular', style: style),
              Text('―', style: style),
              Text(catalog != null ? (catalog.type[0].toUpperCase() + catalog.type.substring(1)) : 'Movie', style: style),
            ],
          ),
        ),

        SizedBox(
          height: Device.screenType == ScreenType.desktop ? 22.h : 23.h,
          child: ScrollableWidget(
            controller: _controller,
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.catalogItems != null ? widget.catalogItems?.length : 10,
              itemBuilder: (context, index) {
                return CatalogItemWidget(catalogItem: catalogItems?[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
