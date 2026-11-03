import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogRow extends StatelessWidget {
  final Catalog? catalog;
  final List<CatalogItem>? catalogItems;
  const CatalogRow({
    super.key,
    required this.catalog,
    required this.catalogItems,
  });

  @override
  Widget build(BuildContext context) {
    final type = catalog?.type ?? 'movie';
    final label = type.isEmpty
        ? ''
        : '${type[0].toUpperCase()}${type.substring(1)}';
    final title = catalog == null
        ? 'Popular ― Movie'
        : '${catalog!.name} ― $label';
    return HomeSection(
      title: title,
      child: MediaShelf(
        itemCount: catalogItems?.length ?? 10,
        itemBuilder: (context, index) {
          final item = catalogItems?[index];
          return CatalogItemWidget(
            key: ValueKey(item?.id ?? 'skeleton-$index'),
            catalogItem: item,
          );
        },
      ),
    );
  }
}
