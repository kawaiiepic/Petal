import 'dart:math' as math;
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A consistent artwork row or vertical grid. Owns its scrolling lifecycle.
///
/// [orientation] controls portrait/landscape card proportions independently of
/// [scrollDirection]. Vertical grids expand inside a page scroll view, or scroll
/// themselves when their parent provides a bounded height.
class MediaShelf extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Orientation orientation;
  final Axis scrollDirection;
  final double cardHeight;
  final double spacing;
  final double? cardWidth;
  final EdgeInsets? padding;

  const MediaShelf({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.orientation = Orientation.portrait,
    this.scrollDirection = Axis.horizontal,
    this.cardHeight = 180,
    this.spacing = 16,
    this.cardWidth,
    this.padding,
  }) : assert(itemCount >= 0),
       assert(cardHeight > 0),
       assert(cardWidth == null || cardWidth > 0),
       assert(spacing >= 0);

  @override
  State<MediaShelf> createState() => _MediaShelfState();
}

class _MediaShelfState extends State<MediaShelf> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = MediaQuery.sizeOf(context).width < 600;
        final padding = widget.padding ?? (compact
            ? const EdgeInsets.symmetric(vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
        final spacing = compact && widget.spacing == 16 ? 8.0 : widget.spacing;
        final ratio = widget.orientation == Orientation.portrait ? 3 / 4 : 16 / 9;
        var height = widget.cardHeight;
        if (compact && widget.scrollDirection == Axis.horizontal &&
            widget.orientation == Orientation.landscape &&
            widget.cardWidth == null && constraints.hasBoundedWidth) {
          final available = math.max(0.0, constraints.maxWidth - padding.horizontal);
          height = math.min(height, available * .78 / ratio);
        }
        final width = widget.cardWidth ?? height * ratio;
        if (widget.scrollDirection == Axis.vertical) {
          return GridView.builder(
            controller: _controller,
            primary: false,
            shrinkWrap: !constraints.hasBoundedHeight,
            physics: constraints.hasBoundedHeight
                ? null : const NeverScrollableScrollPhysics(),
            padding: padding,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: width + spacing,
              childAspectRatio: ratio,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
          );
        }
        return SizedBox(
          height: height + padding.vertical,
          child: ScrollableWidget(
            controller: _controller,
            offset: 0,
            child: ListView.separated(
              controller: _controller,
              primary: false,
              scrollDirection: Axis.horizontal,
              padding: padding,
              itemCount: widget.itemCount,
              separatorBuilder: (_, _) => SizedBox(width: spacing),
              itemBuilder: (context, index) => SizedBox(
                width: width,
                child: widget.itemBuilder(context, index),
              ),
            ),
          ),
        );
      },
    );
  }
}
