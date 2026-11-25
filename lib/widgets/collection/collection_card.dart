import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/collection_progress.dart';
import 'package:petal/utils/watch_meta.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// The same landscape artwork and playback caption used on Home.
class CollectionCard extends StatelessWidget {
  const CollectionCard({super.key, required this.entry, this.onManageHistory});

  final CollectionHistoryEntry entry;
  final VoidCallback? onManageHistory;

  WatchHistoryItem get item => entry.item;

  WatchMetaOverlay _overlay() {
    final finished = isFinished(item, tmdbEpisodeCount: entry.episodeCount);
    if (item.mediaType == MediaType.movie) {
      final metadata = entry.metadata;
      final runtime = metadata is TmdbMovie ? metadata.runtime ?? 0 : 0;
      final partial = WatchProgress.isPartial(item.completion);
      final left = WatchMeta.minutes(((1 - item.completion) * runtime).round());
      return WatchMetaOverlay(
        playback: true,
        episodeLabel: 'Movie',
        durationLabel: WatchMeta.minutes(runtime),
        progress: partial ? item.completion : null,
        remainingLabel: finished
            ? 'Finished'
            : partial
            ? (left.isEmpty
                  ? '${(item.completion * 100).round()}%'
                  : '$left left')
            : 'Not started',
      );
    }

    final metadata = entry.metadata;
    final show = metadata is TmdbShow ? metadata : null;
    final runtime = WatchMeta.episodeMinutes(show);
    final aired = show == null ? 0 : WatchMeta.airedEpisodes(show);
    final watched = WatchMeta.watchedEpisodesFromHistory(item);
    final episode = item.episodes
        .where((episode) => WatchProgress.isPartial(episode.completion))
        .lastOrNull;
    final remaining = WatchMeta.remainingLabel(
      left: (aired - watched).clamp(0, aired),
      minutesEach: runtime,
      currentCompletion: episode?.completion ?? 0,
    );
    return WatchMetaOverlay(
      playback: true,
      episodeLabel: episode == null
          ? 'Series'
          : 'S${episode.season} · E${episode.episode}',
      durationLabel: WatchMeta.minutes(runtime),
      progress: episode?.completion,
      remainingLabel: finished
          ? 'Finished'
          : remaining ??
                (episode != null
                    ? '${(episode.completion * 100).round()}%'
                    : watched > 0
                    ? '$watched watched'
                    : 'Not started'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isShow = item.mediaType == MediaType.show;
    final title = entry.title;
    final path = entry.artworkPath;
    final infoRoute = '/${isShow ? 'series' : 'movie'}?tmdb=${item.tmdbId}';
    final episodeCount = item.episodes.length;
    final relative = WatchMeta.relative(item.updatedAt);
    final historyLabel = isShow
        ? '$episodeCount ${episodeCount == 1 ? 'episode' : 'episodes'} · $relative'
        : relative;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: MediaCard(
            orientation: Orientation.landscape,
            label: title,
            imageUrl: path == null || path.isEmpty
                ? null
                : Api.proxyImage(
                    path.startsWith('http')
                        ? path
                        : 'https://image.tmdb.org/t/p/w780$path',
                  ),
            target: MediaCardTarget(
              tmdbId: item.tmdbId,
              type: item.mediaType,
              totalEpisodes: entry.episodeCount,
            ),
            primaryActionLabel: 'View title',
            showDefaultContextMenu: onManageHistory == null,
            extraContextItems: [
              if (onManageHistory case final manage?) ...[
                MenuButton(
                  leading: const Icon(LucideIcons.history),
                  child: const Text('Manage progress'),
                  onPressed: (_) => manage(),
                ),
                MenuButton(
                  leading: const Icon(LucideIcons.info),
                  child: const Text('More Info'),
                  onPressed: (_) => context.push(infoRoute),
                ),
              ],
            ],
            showProgress: false,
            onTap: onManageHistory ?? () => context.push(infoRoute),
            overlay: Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _overlay(),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          onManageHistory == null ? relative : historyLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}
