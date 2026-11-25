import 'package:petal/api/api.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/person_cast_credit.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class FilmographyCard extends StatelessWidget {
  final PersonCastCredit credit;
  const FilmographyCard({super.key, required this.credit});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: MediaCard(
        label: credit.title,
        imageUrl: credit.posterPath == null ? null :
          Api.proxyImage('https://image.tmdb.org/t/p/w342${credit.posterPath}'),
        target: MediaCardTarget(tmdbId: credit.id, type: credit.mediaType),
        onTap: () => context.push('/${credit.mediaType == MediaType.show ? 'series' : 'movie'}?tmdb=${credit.id}'),
      )),
      const SizedBox(height: 6),
      Text(credit.title, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      Text([if (credit.releaseYear > 0) '${credit.releaseYear}',
        if (credit.character?.isNotEmpty ?? false) credit.character!].join(' · '),
        maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground)),
    ],
  );
}
