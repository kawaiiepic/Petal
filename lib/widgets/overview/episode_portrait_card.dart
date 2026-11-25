import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/overview/episode_action_menu.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class EpisodePortraitCard extends StatelessWidget {
  final int tmdbId;
  final TmdbEpisode episode;
  final String? fallbackImage;
  const EpisodePortraitCard({super.key, required this.tmdbId,
    required this.episode, this.fallbackImage});

  @override
  Widget build(BuildContext context) {
    final label = 'S${episode.seasonNumber} · E${episode.episodeNumber}';
    final image = episode.stillUrl ??
        (fallbackImage == null ? null : 'https://image.tmdb.org/t/p/w342$fallbackImage');
    final future = episode.airDate?.isAfter(DateTime.now()) ?? false;
    return EpisodeActionMenu(
      tmdbId: tmdbId,
      season: episode.seasonNumber,
      episode: episode.episodeNumber,
      builder: (context, watched, busy, play) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: MediaCard(
              orientation: Orientation.portrait,
              imageUrl: image,
              label: episode.name,
              showLogo: false,
              showDefaultContextMenu: false,
              target: MediaCardTarget(tmdbId: tmdbId, type: MediaType.show,
                season: episode.seasonNumber, episode: episode.episodeNumber),
              onTap: () => context.push('/episode?tmdb=$tmdbId&s=${episode.seasonNumber}&e=${episode.episodeNumber}'),
              overlay: watched ? const Positioned(top: 8, right: 8,
                child: Icon(LucideIcons.check, color: Colors.white, size: 20)) : null,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: future ? Colors.red :
              Theme.of(context).colorScheme.mutedForeground)),
          Text(episode.name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
