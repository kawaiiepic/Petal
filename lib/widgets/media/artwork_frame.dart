import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Inset hairline over the artwork, not a border that shrinks the image.
class ArtworkFrame extends StatelessWidget {
  const ArtworkFrame({
    super.key,
    required this.child,
    this.radius = 12,
    this.highlighted = false,
  });

  final Widget child;
  final double radius;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: corners,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(
            color: Colors.white.withValues(alpha: highlighted ? .82 : .18),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
