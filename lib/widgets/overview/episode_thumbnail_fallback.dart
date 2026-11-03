import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EpisodeThumbnailFallback extends StatelessWidget {
  const EpisodeThumbnailFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 68,
      color: Colors.white.withValues(alpha: 0.12),
      child: Icon(LucideIcons.tv, color: Colors.white.withValues(alpha: 0.38)),
    );
  }
}
