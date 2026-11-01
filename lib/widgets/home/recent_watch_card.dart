import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/recent_watch.dart';
import 'package:petal/utils/watch_meta.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class RecentWatchCard extends StatelessWidget {
  final RecentWatch item;

  const RecentWatchCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isShow =
        item.type == MediaType.show &&
        item.season != null &&
        item.episode != null;
    return FutureBuilder(
      future: isShow
          ? Future.wait<dynamic>([
              TMDB.tvShow(item.tmdbId),
              TMDB.tvEpisode(item.tmdbId, item.season!, item.episode!),
            ])
          : item.type == MediaType.show
          ? TMDB.tvShow(item.tmdbId)
          : TMDB.movie(item.tmdbId),
      builder: (context, snapshot) {
        String? image;
        int? totalEpisodes;

        if (snapshot.hasData) {
          if (isShow) {
            final parts = snapshot.data as List<dynamic>;
            final show = parts[0] as TmdbShow;
            totalEpisodes = show.numberOfEpisodes;
            final episode = parts[1] as TmdbEpisode;
            final still = episode.stillPath;
            final backdrop = show.backdropPath;
            final path = (still != null && still.isNotEmpty) ? still : backdrop;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else if (item.type == MediaType.show) {
            final show = snapshot.data as TmdbShow;
            totalEpisodes = show.numberOfEpisodes;
            final path = show.backdropPath;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          } else {
            final movie = snapshot.data as TmdbMovie;
            final path = movie.backdropPath ?? movie.posterPath;
            if (path != null && path.isNotEmpty) {
              image = path.startsWith('http')
                  ? Api.proxyImage(path)
                  : Api.proxyImage('https://image.tmdb.org/t/p/w780$path');
            }
          }
        }

        return MediaCard(
          orientation: Orientation.landscape,
          onTap: () => context.push(
            item.type == MediaType.show
                ? '/series?tmdb=${item.tmdbId}'
                : '/movie?tmdb=${item.tmdbId}',
          ),
          imageUrl: image,
          overlay: Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: WatchMetaOverlay(
              durationLabel: isShow
                  ? 'S${item.season} \u00b7 E${item.episode}'
                  : null,
              remainingLabel: WatchMeta.relative(item.at),
            ),
          ),
          target: MediaCardTarget(
            tmdbId: item.tmdbId,
            type: item.type,
            totalEpisodes: totalEpisodes,
            season: item.season,
            episode: item.episode,
          ),
        );
      },
    );
  }
}
