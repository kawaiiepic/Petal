import 'package:blssmpetal/models/catalog_item.dart';
import 'package:flutter/material.dart';

class CatalogItemWidget extends StatefulWidget {
  final CatalogItem catalogItem;

  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  State<StatefulWidget> createState() => _CatalogItemWidget();
}

class _CatalogItemWidget extends State<CatalogItemWidget> {
  late final CatalogItem catalogItem;

  @override
  void initState() {
    super.initState();
    catalogItem = widget.catalogItem;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 10, child: Text(catalogItem.name));
  }
}
