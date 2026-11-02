import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class MediaArtwork extends StatelessWidget {
  final String? imageUrl;
  final bool isLoading;
  final BoxFit fit;
  final int? cacheWidth;
  const MediaArtwork({
    super.key,
    this.imageUrl,
    this.isLoading = false,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const MediaArtworkPlaceholder(loading: true);
    final url = imageUrl;
    if (url == null || url.isEmpty) return const MediaArtworkPlaceholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) => const MediaArtworkPlaceholder(loading: true),
      errorWidget: (_, _, _) => const MediaArtworkPlaceholder(),
    );
  }
}
