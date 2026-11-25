import 'package:petal/widgets/ios/ios_context_menu.dart';
import 'package:petal/widgets/media/artwork_frame.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HoverableItem extends StatefulWidget {
  final Widget? image;
  final Widget? extraWidget;
  final VoidCallback? onTap;
  final List<MenuItem>? contextItems;
  final Orientation orientation;

  const HoverableItem({
    super.key,
    required this.image,
    this.onTap,
    this.contextItems,
    this.orientation = Orientation.portrait,
    this.extraWidget,
  });

  @override
  State<StatefulWidget> createState() => _HoverableItemState();
}

class _HoverableItemState extends State<HoverableItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final card = AspectRatio(
      aspectRatio: widget.orientation == Orientation.portrait ? 3 / 4 : 16 / 9,
      child: ArtworkFrame(
        highlighted: _isHovering,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: _isHovering ? 1.07 : 1,
              duration: const Duration(milliseconds: 250),
              child: widget.image,
            ),
            if (widget.extraWidget != null) widget.extraWidget!,
          ],
        ),
      ),
    );

    final tappable = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: card,
      ),
    );

    if (widget.contextItems == null || widget.contextItems!.isEmpty)
      return tappable;

    return PetalContextMenu(items: widget.contextItems!, child: tappable);
  }
}
