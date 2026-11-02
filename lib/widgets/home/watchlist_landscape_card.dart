import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
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
  final bool openEpisode;

  const WatchlistLandscapeCard({
    super.key,
    required this.item,
    this.openEpisode = false,
  });

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
        final season = isShow && snapshot.hasData
            ? (snapshot.data as TmdbShow)
                      .mainSeasons
                      .firstOrNull
                      ?.seasonNumber ??
                  1
            : 1;
        return MediaCard(
          isLoading: snapshot.connectionState != ConnectionState.done,
          orientation: Orientation.landscape,
          onTap: () => context.push(
            isShow
                ? openEpisode
                      ? '/episode?tmdb=${item.tmdbId}&s=$season&e=1'
                      : '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          imageUrl: image,
          overlay: openEpisode
              ? Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: WatchMetaOverlay(
                    episodeLabel: isShow ? 'S$season · E1' : 'Movie',
                  ),
                )
              : null,
          label: name,
          target: MediaCardTarget(
            tmdbId: item.tmdbId,
            type: item.type,
            season: openEpisode && isShow ? season : null,
            episode: openEpisode && isShow ? 1 : null,
            totalEpisodes: isShow && snapshot.hasData
                ? (snapshot.data as dynamic).numberOfEpisodes as int?
                : null,
          ),
        );
      },
    );
  }
}
