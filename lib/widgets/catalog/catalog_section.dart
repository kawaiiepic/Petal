import 'package:petal/api/api_cache.dart';
import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_row.dart';
import 'package:petal/widgets/connection_error_view.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogSection extends StatefulWidget {
  final Catalog catalog;
  const CatalogSection({super.key, required this.catalog});

  @override
  State<CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends State<CatalogSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<CatalogItem>>(
      future: ApiCache.getCatalogItems(widget.catalog),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ConnectionErrorView(
              error: snapshot.error,
              title: "Couldn't load ${widget.catalog.name}",
            ),
          );
        }
        return CatalogRow(catalog: widget.catalog, catalogItems: snapshot.data);
      },
    );
  }
}
