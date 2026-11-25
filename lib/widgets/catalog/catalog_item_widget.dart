import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/artwork_caption.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogItemWidget extends StatelessWidget {
  final CatalogItem? catalogItem;
  final int? rank;
  const CatalogItemWidget({super.key, required this.catalogItem, this.rank});

  @override
  Widget build(BuildContext context) {
    final item = catalogItem;
    final poster = item?.poster ?? '';
    final genre = item?.genres
        .where((genre) => genre.trim().isNotEmpty)
        .firstOrNull;
    final subtitle =
        genre ?? (item != null && item.year > 0 ? '${item.year}' : null);
    return MediaCard(
      isLoading: item == null,
      imageUrl: poster.isEmpty || poster.contains('blossomvale.dev')
          ? poster
          : Api.proxyImage(poster),
      label: item?.name,
      semanticLabel: item == null
          ? null
          : [if (rank != null) '$rank.', item.name, ?subtitle].join(' '),
      overlay: item == null
          ? null
          : Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Stack(
                    children: [
                      if (subtitle != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ArtworkCaption(
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFE6E7EB),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      if (rank != null)
                        Positioned(
                          top: 7,
                          left: 8,
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 7),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      target: item == null
          ? null
          : MediaCardTarget(
              tmdbId: int.tryParse(item.id),
              imdbId: int.tryParse(item.id) == null ? item.id : null,
              type: item.type == 'movie' ? MediaType.movie : MediaType.show,
            ),
      onTap: item == null
          ? null
          : () {
              final type = item.type == 'movie' ? 'movie' : 'series';
              final key = int.tryParse(item.id) == null ? 'imdb' : 'tmdb';
              context.push('/$type?$key=${Uri.encodeQueryComponent(item.id)}');
            },
    );
  }
}
