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
  final EdgeInsets padding;

  const MediaShelf({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.orientation = Orientation.portrait,
    this.scrollDirection = Axis.horizontal,
    this.cardHeight = 180,
    this.spacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  }) : assert(itemCount >= 0),
       assert(cardHeight > 0),
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
    final ratio = widget.orientation == Orientation.portrait ? 3 / 4 : 16 / 9;
    final width = widget.cardHeight * ratio;

    if (widget.scrollDirection == Axis.vertical) {
      return LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          controller: _controller,
          primary: false,
          shrinkWrap: !constraints.hasBoundedHeight,
          physics: constraints.hasBoundedHeight
              ? null
              : const NeverScrollableScrollPhysics(),
          padding: widget.padding,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: width + widget.spacing,
            childAspectRatio: ratio,
            mainAxisSpacing: widget.spacing,
            crossAxisSpacing: widget.spacing,
          ),
          itemCount: widget.itemCount,
          itemBuilder: widget.itemBuilder,
        ),
      );
    }

    return SizedBox(
      height: widget.cardHeight + widget.padding.vertical,
      child: ScrollableWidget(
        controller: _controller,
        offset: 0,
        child: ListView.separated(
          controller: _controller,
          primary: false,
          scrollDirection: Axis.horizontal,
          padding: widget.padding,
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => SizedBox(width: widget.spacing),
          itemBuilder: (context, index) =>
              SizedBox(width: width, child: widget.itemBuilder(context, index)),
        ),
      ),
    );
  }
}
