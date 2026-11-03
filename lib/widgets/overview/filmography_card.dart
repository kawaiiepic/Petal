import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/person_cast_credit.dart';
import 'package:petal/widgets/overview/poster_fallback.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FilmographyCard extends StatelessWidget {
  final PersonCastCredit credit;

  const FilmographyCard({required this.credit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${credit.id}'), // adjust to your route
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: credit.posterPath != null
                ? Image.network(
                    'https://image.tmdb.org/t/p/w185${credit.posterPath}',
                    width: 110,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => PosterFallback(),
                  )
                : PosterFallback(),
          ),
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
