import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/recommended_movie.dart';
import 'package:petal/widgets/overview/recommendation_metadata_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class MovieRecommendationCard extends StatelessWidget {
  final RecommendedMovie? movie;
  const MovieRecommendationCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: movie?.title,
      button: movie != null,
      child: GestureDetector(
        onTap: movie == null ? null : () => context.push('/movie?tmdb=${movie!.id}'),
        child: SizedBox(
          width: 110,
          height: 155,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaArtwork(
                  imageUrl: movie?.posterPath == null
                      ? null
                      : 'https://image.tmdb.org/t/p/w342${movie!.posterPath}',
                  isLoading: movie == null,
                ),
                if (movie != null)
                  RecommendationMetadataOverlay(
                    rating: movie!.voteAverage,
                    year: movie!.releaseDate?.year,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
