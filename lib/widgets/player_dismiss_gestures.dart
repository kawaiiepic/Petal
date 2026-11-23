import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Recognizes player dismissal without competing with controls for drag events.
class PlayerDismissGestures extends StatefulWidget {
  const PlayerDismissGestures({
    super.key,
    required this.onDismiss,
    required this.child,
    this.downStartFraction = .65,
  });

  final VoidCallback onDismiss;
  final Widget child;
  final double downStartFraction;

  @override
  State<PlayerDismissGestures> createState() => _PlayerDismissGesturesState();
}

class _PlayerDismissGesturesState extends State<PlayerDismissGestures> {
  int? _pointer;
  Offset? _start;
  bool _fromLeft = false;
  bool _canPullDown = false;

  void _down(PointerDownEvent event) {
    if (_pointer != null) {
      _start = null;
      return;
    }
    if (event.kind != PointerDeviceKind.touch) return;
    _pointer = event.pointer;
    _start = event.localPosition;
    final height = context.size?.height ?? 0;
    _fromLeft = event.localPosition.dx <= 22;
    _canPullDown = event.localPosition.dy <= height * widget.downStartFraction;
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    final start = _start;
    _start = null;
    if (start == null || ModalRoute.of(context)?.isCurrent == false) return;
    final delta = event.localPosition - start;
    final right =
        _fromLeft && delta.dx >= 64 && delta.dx > delta.dy.abs() * 1.5;
    final down =
        _canPullDown && delta.dy >= 72 && delta.dy > delta.dx.abs() * 1.5;
    if (right || down) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: (event) {
      if (event.pointer == _pointer) {
        _pointer = null;
        _start = null;
      }
    },
    child: widget.child,
  );
}
