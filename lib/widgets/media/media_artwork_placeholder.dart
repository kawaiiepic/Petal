import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shadcn_flutter_skeletonizer/shadcn_flutter_skeletonizer.dart';

/// Artwork keeps the card's dimensions while loading, missing, or unavailable.
class MediaArtworkPlaceholder extends StatelessWidget {
  final bool loading;
  const MediaArtworkPlaceholder({super.key, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      color: Theme.of(context).colorScheme.muted,
      child: loading
          ? null
          : const Center(child: Icon(LucideIcons.imageOff, size: 24)),
    );
    return loading
        ? ExcludeSemantics(child: surface.asSkeleton(leaf: true).asSkeleton())
        : Semantics(label: 'Artwork unavailable', child: surface);
  }
}
