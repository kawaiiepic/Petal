import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/recommended_show.dart';
import 'package:petal/widgets/overview/recommendation_metadata_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ShowRecommendationCard extends StatelessWidget {
  final RecommendedShow? show;
  const ShowRecommendationCard({super.key, required this.show});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: show?.name,
      button: show != null,
      child: GestureDetector(
        onTap: show == null ? null : () => context.push('/series?tmdb=${show!.id}'),
        child: SizedBox(
          width: 110,
          height: 155,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaArtwork(
                  imageUrl: show?.posterPath == null
                      ? null
                      : 'https://image.tmdb.org/t/p/w342${show!.posterPath}',
                  isLoading: show == null,
                ),
                if (show != null)
                  RecommendationMetadataOverlay(
                    rating: show!.voteAverage,
                    year: show!.firstAirDate?.year,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
