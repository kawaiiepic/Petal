import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/recommended_show.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ShowRecommendationCard extends StatelessWidget {
  final RecommendedShow? show;
  const ShowRecommendationCard({required this.show});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          show != null ? context.push('/series?tmdb=${show!.id}') : null,
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 110,
                height: 155,
                child: MediaArtwork(
                  imageUrl: show?.posterPath == null
                      ? null
                      : 'https://image.tmdb.org/t/p/w342${show!.posterPath}',
                  isLoading: show == null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              show?.name ?? 'Show Name...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u2605 ${show?.voteAverage.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${show?.firstAirDate?.year.toString()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
