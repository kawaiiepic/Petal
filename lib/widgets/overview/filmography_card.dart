import 'package:petal/api/api.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/person_cast_credit.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FilmographyCard extends StatelessWidget {
  final PersonCastCredit credit;

  const FilmographyCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie?tmdb=${credit.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: double.infinity,
              child: MediaArtwork(imageUrl: credit.posterPath == null ? null :
                Api.proxyImage('https://image.tmdb.org/t/p/w185${credit.posterPath}'))),
          )),
          const SizedBox(height: 6),
          Text(
            credit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (credit.character != null)
            Text(
              credit.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }
}
