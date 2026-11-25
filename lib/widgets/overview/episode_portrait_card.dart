import 'package:go_router/go_router.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/overview/overview_thumbnail_caption.dart';
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
      builder: (context, watched, busy, play) => ColorFiltered(
        colorFilter: future
            ? const ColorFilter.matrix(<double>[
                .2126, .7152, .0722, 0, 0,
                .2126, .7152, .0722, 0, 0,
                .2126, .7152, .0722, 0, 0,
                0, 0, 0, 1, 0,
              ])
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Opacity(
          opacity: future ? .55 : 1,
          child: MediaCard(
        orientation: Orientation.landscape,
        imageUrl: image,
        label: episode.name,
        semanticLabel: '$label · ${episode.name} · ${episode.releaseLabel}',
        showLogo: false,
        showDefaultContextMenu: false,
        target: MediaCardTarget(tmdbId: tmdbId, type: MediaType.show,
          season: episode.seasonNumber, episode: episode.episodeNumber),
        onTap: () => context.push('/episode?tmdb=$tmdbId&s=${episode.seasonNumber}&e=${episode.episodeNumber}'),
        overlay: Positioned.fill(
          child: Stack(
            children: [
              OverviewThumbnailCaption(title: episode.name, subtitle: label,
                subtitleColor: future ? Colors.red : null),
              Positioned(top: 6, left: 6, right: watched ? 36 : 6,
                child: Align(alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(5)),
                    child: Text(episode.releaseLabel, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: future ? const Color(0xFFFFB86B) : Colors.white)),
                  ),
                ),
              ),
              if (watched)
                const Positioned(top: 8, right: 8,
                  child: Icon(LucideIcons.check, color: Colors.white, size: 20)),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
