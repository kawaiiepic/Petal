import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/recommended_movie.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class MovieRecommendationCard extends StatelessWidget {
  final RecommendedMovie? movie;

  const MovieRecommendationCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          movie != null ? context.push('/movie?tmdb=${movie!.id}') : null,
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
                  imageUrl: movie?.posterPath == null
                      ? null
                      : 'https://image.tmdb.org/t/p/w342${movie!.posterPath}',
                  isLoading: movie == null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie?.title ?? 'Movie Name...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '★ ${movie?.voteAverage.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${movie?.releaseDate?.year.toString()}',
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
