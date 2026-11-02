import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A visible buffer layer, distinct from both the empty and played track.
class SeekBufferTrack extends StatelessWidget {
  final double fraction;
  const SeekBufferTrack({super.key, required this.fraction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    return IgnorePointer(
      child: Semantics(
        label: 'Buffered media',
        value: '${(value * 100).round()}%',
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.density.baseGap * theme.scaling * .5,
          ),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.radiusSm),
              child: SizedBox(
                height: 6 * theme.scaling,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.white.withValues(alpha: .12)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: .55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
