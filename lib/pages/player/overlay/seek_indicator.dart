import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SeekIndicator extends StatelessWidget {
  final bool visible;
  final int seconds;
  final bool isLeft;

  const SeekIndicator({
    super.key,
    required this.visible,
    required this.seconds,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedOpacity(
            opacity: visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: visible ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isLeft ? LucideIcons.rewind : LucideIcons.fastForward, color: Colors.white, size: 28),
                    if (seconds > 10) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${seconds}s',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
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
