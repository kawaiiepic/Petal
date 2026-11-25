import 'package:flutter/services.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:flutter/widgets.dart' show DraggableScrollableSheet, DraggableScrollableController, DraggableScrollableNotification;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A route-backed episode preview: compact-layout sheet, desktop-layout dialog.
class EpisodeSheetPage extends Page<void> {
  final Widget Function(ScrollController?) builder;
  const EpisodeSheetPage({required super.key, required this.builder});

  @override
  Route<void> createRoute(BuildContext context) => RawDialogRoute<void>(
    settings: this,
    barrierDismissible: true,
    barrierLabel: 'Close episode overview',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _EpisodeSheet(builder: builder),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      if (TvLayout.isCompact(context)) {
        return SlideTransition(
          position: eased.drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
          child: child,
        );
      }
      return FadeTransition(opacity: eased, child: child);
    },
  );
}

class _EpisodeSheet extends StatefulWidget {
  final Widget Function(ScrollController?) builder;
  const _EpisodeSheet({required this.builder});

  @override
  State<_EpisodeSheet> createState() => _EpisodeSheetState();
}

class _EpisodeSheetState extends State<_EpisodeSheet> {
  final _drag = DraggableScrollableController();
  static const _initial = .72;
  static const _minimum = .40;
  bool _closing = false;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _close() {
    if (!mounted || _closing || ModalRoute.of(context)?.isCurrent != true) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  void _finishDrag() {
    if (!_drag.isAttached || _closing) return;
    if (_drag.size < .55) {
      _close();
    } else {
      _drag.animateTo(_drag.size > .86 ? 1 : _initial,
        duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    }
  }

  Widget _surface(BuildContext context, ScrollController? controller, {required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: compact
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : BorderRadius.circular(24),
      child: ColoredBox(
        color: colors.background,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: compact ? (details) {
                if (_drag.isAttached) {
                  final next = _drag.size - _drag.pixelsToSize(details.delta.dy);
                  _drag.jumpTo(next.clamp(_minimum, 1.0).toDouble());
                }
              } : null,
              onVerticalDragEnd: compact ? (_) => _finishDrag() : null,
              child: Column(
                children: [
                  if (compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Episode overview',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                        Semantics(
                          label: 'Close episode overview',
                          button: true,
                          child: glass.GlassButton.custom(
                            width: 40, height: 40, useOwnLayer: true,
                            onTap: _close,
                            child: Icon(LucideIcons.x, size: 18, color: colors.foreground),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: widget.builder(controller)),
            if (compact) SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = TvLayout.isCompact(context);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Focus(
        autofocus: true,
        child: compact
            ? SafeArea(
                bottom: false,
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    if (notification.extent <= notification.minExtent + .001) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    controller: _drag,
                    initialChildSize: _initial,
                    minChildSize: _minimum,
                    maxChildSize: 1,
                    snap: true,
                    snapSizes: const [_initial],
                    builder: (context, controller) =>
                        _surface(context, controller, compact: true),
                  ),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820, maxHeight: 850),
                      child: _surface(context, null, compact: false),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
