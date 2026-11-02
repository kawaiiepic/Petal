import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchlistLandscapeCard extends StatelessWidget {
  final LibraryTitle item;

  const WatchlistLandscapeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow = item.type == MediaType.show;
    return FutureBuilder(
      future: isShow ? TMDB.tvShow(item.tmdbId) : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        String name = '';
        if (snapshot.hasData) {
          if (isShow) {
            final show = snapshot.data as dynamic;
            final backdrop = show.backdropPath as String?;
            final poster = show.posterPath as String?;
            name = (show.name as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty)
                ? backdrop
                : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else {
            final movie = snapshot.data as dynamic;
            final backdrop = movie.backdropPath as String?;
            final poster = movie.posterPath as String?;
            name = (movie.title as String?) ?? '';
            final path = (backdrop != null && backdrop.isNotEmpty)
                ? backdrop
                : poster;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          }
        }
        return MediaCard(
          isLoading: snapshot.connectionState != ConnectionState.done,
          orientation: Orientation.landscape,
          onTap: () => context.push(
            isShow
                ? '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          imageUrl: image,
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
