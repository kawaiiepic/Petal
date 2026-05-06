import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/pages/catalog_item.dart';
import 'package:petal/pages/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class CatalogRow extends StatefulWidget {
  final Catalog catalog;
  final List<CatalogItem> catalogItems;

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
    final Catalog catalog = widget.catalog;
    final List<CatalogItem> catalogItems = widget.catalogItems.toList();
    final style = TextStyle(fontSize: 16.px);

    return Column(
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(catalog.name, style: style),
            Text('―', style: style),
            Text(catalog.type[0].toUpperCase() + catalog.type.substring(1), style: style),
          ],
        ),

        SizedBox(
          height: 25.h,
          child: ScrollableWidget(
            controller: _controller,
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: catalogItems.length,
              itemBuilder: (context, index) {
                return CatalogItemWidget(key: ValueKey(catalog.id), catalogItem: catalogItems[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
