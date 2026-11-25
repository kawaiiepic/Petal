import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shared banner timing, including route visibility and interaction pauses.
class FeaturedAutoplay extends StatefulWidget {
  const FeaturedAutoplay({
    super.key,
    required this.enabled,
    required this.onAdvance,
    required this.child,
  });

  static const interval = Duration(seconds: 7);

  static Animation<double> progressOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_FeaturedProgress>()
          ?.animation ??
      const AlwaysStoppedAnimation(0.0);
  final bool enabled;
  final VoidCallback onAdvance;
  final Widget child;

  @override
  State<FeaturedAutoplay> createState() => _FeaturedAutoplayState();
}

class _FeaturedAutoplayState extends State<FeaturedAutoplay>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: FeaturedAutoplay.interval,
  );
  Timer? _timer;
  final _pointers = <int>{};
  bool _available = false;
  bool _foreground = true;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _available =
        (ModalRoute.isCurrentOf(context) ?? true) &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant FeaturedAutoplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    _progress.stop();
    if (!widget.enabled ||
        !_available ||
        !_foreground ||
        _focused ||
        _pointers.isNotEmpty)
      return;
    _progress.forward(from: 0);
    _timer = Timer(FeaturedAutoplay.interval, () {
      final box = context.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final bounds = box.localToGlobal(Offset.zero) & box.size;
        if (bounds.overlaps(Offset.zero & MediaQuery.sizeOf(context))) {
          widget.onAdvance();
        }
      }
      _schedule();
    });
  }

  void _pointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      _focused = focused;
      _schedule();
    },
    child: Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointers.add(event.pointer);
        _schedule();
      },
      onPointerUp: _pointerEnd,
      onPointerCancel: _pointerEnd,
      child: _FeaturedProgress(animation: _progress, child: widget.child),
    ),
  );
}

class _FeaturedProgress extends InheritedWidget {
  const _FeaturedProgress({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_FeaturedProgress oldWidget) =>
      animation != oldWidget.animation;
}
