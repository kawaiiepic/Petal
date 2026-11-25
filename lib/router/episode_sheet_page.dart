import 'package:flutter/services.dart';
import 'package:petal/navigation/tv_layout.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Content-sized episode preview with a bounded scrollable body.
class EpisodeSheetPage extends Page<void> {
  final Widget Function(ScrollController?) builder;
  final String label;
  final double maxWidth;
  const EpisodeSheetPage({required super.key, required this.builder,
    this.label = 'episode overview', this.maxWidth = 820});

  @override
  Route<void> createRoute(BuildContext context) => RawDialogRoute<void>(
    settings: this,
    barrierDismissible: true,
    barrierLabel: 'Close $label',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _EpisodeSheet(builder: builder, label: label, maxWidth: maxWidth),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final eased = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return TvLayout.isCompact(context)
          ? SlideTransition(
              position: eased.drive(Tween(begin: const Offset(0, 1), end: Offset.zero)),
              child: child,
            )
          : FadeTransition(opacity: eased, child: child);
    },
  );
}

class _EpisodeSheet extends StatefulWidget {
  final Widget Function(ScrollController?) builder;
  final String label;
  final double maxWidth;
  const _EpisodeSheet({required this.builder, required this.label, required this.maxWidth});

  @override
  State<_EpisodeSheet> createState() => _EpisodeSheetState();
}

class _EpisodeSheetState extends State<_EpisodeSheet> {
  double _dragOffset = 0;
  bool _dragging = false;

  void _close() {
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  void _endDrag(double velocity) {
    if (_dragOffset > 80 || velocity > 700) {
      _close();
    } else {
      setState(() {
        _dragging = false;
        _dragOffset = 0;
      });
    }
  }

  Widget _surface(BuildContext context, bool compact) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: compact
          ? const BorderRadius.vertical(top: Radius.circular(28))
          : BorderRadius.circular(24),
      child: ColoredBox(
        color: colors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => setState(() => _dragging = true),
                onVerticalDragUpdate: (details) => setState(() {
                  _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 500.0).toDouble();
                }),
                onVerticalDragEnd: (details) => _endDrag(details.primaryVelocity ?? 0),
                onVerticalDragCancel: () => _endDrag(0),
                child: Semantics(
                  label: 'Swipe down to dismiss ${widget.label}',
                  child: SizedBox(
                    height: 28,
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Flexible(child: widget.builder(null)),
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
        child: SafeArea(
          bottom: !compact,
          child: Padding(
            padding: compact ? const EdgeInsets.only(top: 12) : const EdgeInsets.all(24),
            child: Align(
              alignment: compact ? Alignment.bottomCenter : Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) => ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? constraints.maxWidth : widget.maxWidth,
                    maxHeight: compact ? constraints.maxHeight : constraints.maxHeight.clamp(0.0, 850.0).toDouble(),
                  ),
                  child: AnimatedSlide(
                    duration: _dragging ? Duration.zero : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    offset: Offset(0, _dragOffset / (constraints.maxHeight > 0 ? constraints.maxHeight : 1)),
                    child: _surface(context, compact),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
