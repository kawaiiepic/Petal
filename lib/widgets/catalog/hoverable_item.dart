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
    final card = Container(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: widget.orientation == Orientation.portrait
            ? 3 / 4
            : 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovering ? Colors.white : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovering ? 1.1 : 1,
                  duration: const Duration(milliseconds: 300),
                  child: widget.image,
                ),
                if (widget.extraWidget != null) widget.extraWidget!,
              ],
            ),
          ),
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

    return ContextMenu(
      enabled: true,
      items: widget.contextItems!,
      child: tappable,
    );
  }
}
