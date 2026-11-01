import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ShelfPosterCard extends StatelessWidget {
  final ShelfItem item;

  const ShelfPosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        final posterPath = snapshot.hasData
            ? (snapshot.data as dynamic).posterPath as String?
            : null;
        final name = snapshot.hasData
            ? (isShow
                  ? (snapshot.data as dynamic).name as String?
                  : (snapshot.data as dynamic).title as String?)
            : null;
        return MediaCard(
          onTap: () => context.push(
            isShow
                ? '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          imageUrl: posterPath == null || posterPath.isEmpty
              ? null
              : Api.proxyImage('https://image.tmdb.org/t/p/w342$posterPath'),
          label: name,
          target: MediaCardTarget(
            tmdbId: item.tmdbId,
            type: item.type,
            totalEpisodes: isShow && snapshot.hasData
                ? (snapshot.data as dynamic).numberOfEpisodes as int?
                : null,
          ),
        );
      },
    );
  }
}
