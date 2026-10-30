import 'package:petal/widgets/arrow_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ScrollableWidget extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final double offset;
  const ScrollableWidget({
    super.key,
    required this.child,
    required this.controller,
    this.offset = -50.0,
  });

  @override
  State<StatefulWidget> createState() => _ScrollableWidgetState();
}

class _ScrollableWidgetState extends State<ScrollableWidget> {
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _isHovering = false;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller;

    _controller.addListener(_updateArrows);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  void _updateArrows() {
    if (!mounted || _controller.positions.length != 1) return;

    final position = _controller.position;

    final canLeft = position.pixels > 1;
    final canRight = position.pixels < position.maxScrollExtent - 1;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollBy(double offset) {
    if (_controller.positions.length != 1) return;
    final position = _controller.position;
    final scrollTo = (_controller.offset + offset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_updateArrows);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _updateArrows();
        return false;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            widget.child,

            Positioned(
              left: 8,
              top: widget.offset,
              bottom: 0,

              child: Center(
                child: ArrowButton(
                  visible: _isHovering && _canScrollLeft,
                  icon: LucideIcons.arrowBigLeft,
                  onPressed: () =>
                      _scrollBy(-_controller.position.viewportDimension * 0.85),
                ),
              ),
            ),

            Positioned(
              right: 8,
              top: widget.offset,
              bottom: 0,
              child: Center(
                child: ArrowButton(
                  visible: _isHovering && _canScrollRight,
                  icon: LucideIcons.arrowBigRight,
                  onPressed: () =>
                      _scrollBy(_controller.position.viewportDimension * 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
