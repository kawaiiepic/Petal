import 'package:petal/main.dart';
import 'package:petal/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// iOS-style left-edge swipe that pops the current route.
///
/// The app theme is pinned to [TargetPlatform.linux], so Flutter's built-in
/// Cupertino back gesture never fires. This restores that behavior everywhere
/// except the player and root routes.
class EdgeBackSwipe extends StatelessWidget {
  final Widget child;

  const EdgeBackSwipe({super.key, required this.child});

  static const _edgeWidth = 28.0;
  static const _minVelocity = 280.0;
  static const _minDistance = 64.0;

  bool _blocked() {
    try {
      final path = AppRouter.appRouter.state.uri.path;
      return path == '/' || path == '/login' || path == '/offline' || path == '/player';
    } catch (_) {
      return true;
    }
  }

  bool _canPop() {
    final nav = PetalApp.rootNavigatorKey.currentContext;
    return nav != null && nav.canPop();
  }

  void _pop() {
    final nav = PetalApp.rootNavigatorKey.currentContext;
    if (nav != null && nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _edgeWidth + MediaQuery.paddingOf(context).left,
          child: _EdgeDragStrip(
            onBack: () {
              if (_blocked() || !_canPop()) return;
              _pop();
            },
            minVelocity: _minVelocity,
            minDistance: _minDistance,
          ),
        ),
      ],
    );
  }
}

class _EdgeDragStrip extends StatefulWidget {
  final VoidCallback onBack;
  final double minVelocity;
  final double minDistance;

  const _EdgeDragStrip({
    required this.onBack,
    required this.minVelocity,
    required this.minDistance,
  });

  @override
  State<_EdgeDragStrip> createState() => _EdgeDragStripState();
}

class _EdgeDragStripState extends State<_EdgeDragStrip> {
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
