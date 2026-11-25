import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Caption over the bottom edge of episode and trailer artwork.
class OverviewThumbnailCaption extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? subtitleColor;

  const OverviewThumbnailCaption({super.key, required this.title,
    required this.subtitle, this.subtitleColor});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0, right: 0, bottom: 0,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: .9)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 22, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: subtitleColor ?? Colors.white.withValues(alpha: 0.7))),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ],
          ),
        ),
      ),
    ),
  );
}
