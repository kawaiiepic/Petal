import 'package:cached_network_image/cached_network_image.dart';
import 'package:petal/widgets/catalog/hoverable_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Shared artwork, loading, hover, and context-menu treatment without captions.
class MediaCard extends StatelessWidget {
  final String? imageUrl;
  final Widget? image;
  final String? label;
  final Widget? overlay;
  final VoidCallback? onTap;
  final List<MenuItem>? contextItems;
  final Orientation orientation;

  const MediaCard({
    super.key,
    this.imageUrl,
    this.image,
    this.label,
    this.overlay,
    this.onTap,
    this.contextItems,
    this.orientation = Orientation.portrait,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: Colors.white.withAlpha(20))
        .asSkeleton(leaf: true);
    final url = imageUrl;
    return Semantics(
      label: label,
      button: onTap != null,
      child: HoverableItem(
        orientation: orientation,
        onTap: onTap,
        contextItems: contextItems,
        extraWidget: overlay,
        image:
            image ??
            (url == null || url.isEmpty
                ? placeholder
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 780,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, _) => placeholder,
                    errorWidget: (_, _, _) => Container(
                      color: Colors.white.withAlpha(30),
                      child: const Icon(LucideIcons.imageOff),
                    ),
                  )),
      ),
    );
  }
}
