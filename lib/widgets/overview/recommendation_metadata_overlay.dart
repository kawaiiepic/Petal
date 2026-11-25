import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RecommendationMetadataOverlay extends StatelessWidget {
  final double rating;
  final int? year;
  const RecommendationMetadataOverlay({super.key, required this.rating, this.year});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0, right: 0, bottom: 0,
    child: IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: .9)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (rating > 0)
                Text('★ ${rating.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              if (year != null)
                Text('$year', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      ),
    ),
  );
}
