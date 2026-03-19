import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/catalog_item.dart';
import 'package:blssmpetal/pages/scrollable_widget.dart';
import 'package:flutter/material.dart';

class CatalogRow extends StatefulWidget {
  final Catalog catalog;
  final List<CatalogItem> catalogItems;

  const CatalogRow({super.key, required this.catalog, required this.catalogItems});

  @override
  State<StatefulWidget> createState() => _CatalogRowState();
}

class _CatalogRowState extends State<CatalogRow> {
  final _controller = ScrollController();
  @override
  Widget build(BuildContext context) {
    final Catalog catalog = widget.catalog;
    final List<CatalogItem> catalogItems = widget.catalogItems;
    return Column(
      children: [
        Row(children: [Text(catalog.name), Text('-'), Text(catalog.type[0].toUpperCase() + catalog.type.substring(1))]),
        SizedBox(
          height: 300,
          child: Text('Boop'),
          // child: ScrollableWidget(
          //   controller: _controller,
          //   child: ListView(
          //     controller: _controller,
          //     scrollDirection: Axis.horizontal,
          //     children: [
          //       ...catalogItems.take(10).map((catalogItem) {
          //         return CatalogItemWidget(catalogItem: catalogItem);
          //       }),
          //     ],
          //   ),
          // ),
        ),
      ],
    );
  }
}
