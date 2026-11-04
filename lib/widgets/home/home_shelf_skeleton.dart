import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Reserves the same responsive card geometry as the completed shelf.
class HomeShelfSkeleton extends StatelessWidget {
  final String title;
  final Orientation orientation;
  final double cardHeight;

  const HomeShelfSkeleton({
    super.key,
    required this.title,
    this.orientation = Orientation.portrait,
    this.cardHeight = 180,
  });

  @override
  Widget build(BuildContext context) => HomeSection(
    title: title,
    child: ExcludeFocus(
      child: IgnorePointer(
        child: MediaShelf(
          orientation: orientation,
          cardHeight: cardHeight,
          itemCount: 6,
          itemBuilder: (_, _) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const MediaArtworkPlaceholder(loading: true),
          ),
        ),
      ),
    ),
  );
}
