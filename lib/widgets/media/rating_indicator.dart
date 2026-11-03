import 'package:petal/api/user_library.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RatingIndicator extends StatelessWidget {
  final int tmdbId;
  final MediaType type;

  const RatingIndicator({super.key, required this.tmdbId, required this.type});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: UserLibrary.ratings,
    builder: (context, _, __) {
      final rating = UserLibrary.ratingFor(tmdbId, type);
      if (rating == TitleRating.none) return const SizedBox.shrink();
      final label = rating == TitleRating.love ? 'Loved' : 'Liked';
      return Tooltip(
        tooltip: (_) => Text(label),
        child: Semantics(
          label: label,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xE6101018),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              rating == TitleRating.love
                  ? LucideIcons.heart
                  : LucideIcons.thumbsUp,
              size: 16,
              color: Colors.pink,
            ),
          ),
        ),
      );
    },
  );
}
