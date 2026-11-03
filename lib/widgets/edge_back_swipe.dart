import 'package:petal/app/petal_app.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/widgets/edge_drag_strip.dart';
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
      return path == '/' ||
          path == '/login' ||
          path == '/offline' ||
          path == '/player';
    } catch (_) {
      return true;
    }
  }

  bool _canPop() {
    final ctx = PetalApp.rootNavigatorKey.currentContext;
    return ctx != null && Navigator.of(ctx).canPop();
  }

  void _pop() {
    final ctx = PetalApp.rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final nav = Navigator.of(ctx);
    if (nav.canPop()) nav.pop();
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
          child: EdgeDragStrip(
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
