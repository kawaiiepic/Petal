import 'package:petal/models/catalog.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/navigation/tv_layout.dart';
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
    final compact = TvLayout.isCompact(context);
    final ranked = catalog?.id == 'top';
    final width = (MediaQuery.sizeOf(context).width * .255).clamp(80.0, 138.0);
    final title = ranked
        ? 'Popular ${type == 'movie' ? 'Movies' : 'TV Shows'}'
        : catalog == null
        ? 'Popular ― Movie'
        : '${catalog!.name} ― $label';
    return HomeSection(
      title: title,
      editorial: true,
      child: MediaShelf(
        cardWidth: compact ? width : 126,
        cardHeight: compact ? width * 1.5 : 189,
        spacing: compact ? 12 : 16,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: catalogItems?.length ?? 10,
        itemBuilder: (context, index) {
          final item = catalogItems?[index];
          return CatalogItemWidget(
            key: ValueKey(item?.id ?? 'skeleton-$index'),
            catalogItem: item,
            rank: ranked && item != null && index < 10 ? index + 1 : null,
          );
        },
      ),
    );
  }
}
