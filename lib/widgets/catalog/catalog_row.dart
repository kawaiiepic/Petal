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

class _CatalogRowState extends State<CatalogRow> with AutomaticKeepAliveClientMixin {
  late final ScrollController _controller;
  bool _open = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Catalog? catalog = widget.catalog;
    final List<CatalogItem>? catalogItems = widget.catalogItems?.toList();
    final style = TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp);
    final count = widget.catalogItems != null ? widget.catalogItems!.length : 10;
    final title = catalog == null ? 'Popular ― Movie' : '${catalog.name} ― ${catalog.type[0].toUpperCase()}${catalog.type.substring(1)}';

    return Column(
      children: [
        Skeleton.keep(
          keep: catalog != null,
          child: Button(
            style: ButtonVariance.ghost,
            onPressed: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: style, textAlign: TextAlign.left)),
                  Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          SizedBox(
            height: Device.screenType == ScreenType.desktop ? 22.h : 23.h,
            child: ScrollableWidget(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                cacheExtent: 2000,
                addAutomaticKeepAlives: true,
                itemCount: count,
                itemBuilder: (context, index) {
                  final item = catalogItems?[index];
                  return CatalogItemWidget(key: ValueKey(item?.id ?? 'skeleton-$index'), catalogItem: item);
                },
              ),
            ),
          ),
      ],
    );
  }
}
