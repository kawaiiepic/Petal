import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PosterFallback extends StatelessWidget {
  const PosterFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 155,
      color: Colors.white.withValues(alpha: 0.12),
      child: Icon(
        LucideIcons.ticket,
        color: Colors.white.withValues(alpha: 0.38),
      ),
    );
  }
}
