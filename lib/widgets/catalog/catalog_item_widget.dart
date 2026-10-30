import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogItemWidget extends StatelessWidget {
  final CatalogItem? catalogItem;
  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  Widget build(BuildContext context) {
    final item = catalogItem;
    final poster = item?.poster ?? '';
    return MediaCard(
      imageUrl: poster.isEmpty || poster.contains('blossomvale.dev')
          ? poster
          : Api.proxyImage(poster),
      label: item?.name,
      target: item == null
          ? null
          : MediaCardTarget(
              tmdbId: int.tryParse(item.id),
              imdbId: int.tryParse(item.id) == null ? item.id : null,
              type: item.type == 'movie' ? MediaType.movie : MediaType.show,
            ),
      onTap: item == null
          ? null
          : () => context.push('/${item.type}?imdb=${item.id}'),
    );
  }
}
