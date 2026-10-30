import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EdgeDragStrip extends StatefulWidget {
  final VoidCallback onBack;
  final double minVelocity;
  final double minDistance;

  const EdgeDragStrip({
    required this.onBack,
    required this.minVelocity,
    required this.minDistance,
  });

  @override
  State<EdgeDragStrip> createState() => _EdgeDragStripState();
}

class _EdgeDragStripState extends State<EdgeDragStrip> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0) _dx += details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity >= widget.minVelocity || _dx >= widget.minDistance) {
          widget.onBack();
        }
        _dx = 0;
      },
    );
  }
}
