import 'package:petal/models/library/collection_status.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/utils/collection_progress.dart';
import 'package:petal/utils/watch_meta.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CollectionCard extends StatelessWidget {
  final WatchHistoryItem item;
  final Widget poster;
  final dynamic tmdb;
  final CollectionStatus status;

  const CollectionCard({
    super.key,
    required this.item,
    required this.poster,
    required this.tmdb,
    required this.status,
  });

  int? get _episodeCount => item.mediaType == MediaType.show
      ? (tmdb as dynamic).numberOfEpisodes as int?
      : null;

  String _lastWatched() {
    final d = item.updatedAt.toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.month}/${d.day}/${d.year}';
  }

  String _progressLabel() {
    if (isFinished(item, tmdbEpisodeCount: _episodeCount)) return 'Finished';
    if (item.mediaType == MediaType.movie) {
      final pct = (item.completion * 100).clamp(0, 100).round();
      if (pct <= 0) return 'Not started';
      return '$pct%';
    }
    final watching = item.episodes.where(
      (e) => e.completion > 0 && e.completion < 1,
    );
    if (watching.isNotEmpty) {
      final e = watching.last;
      return 'S${e.season}E${e.episode} ${(e.completion * 100).round()}%';
    }
    final done = item.episodes.where((e) => e.completion >= 1).length;
    return done == 0 ? 'Not started' : '$done watched';
  }

  Widget _progressOverlay() {
    if (item.mediaType == MediaType.movie) {
      final runtime = (tmdb as dynamic).runtime as int? ?? 0;
      String? remaining;
      if (runtime > 0 && item.completion > 0 && item.completion < 1) {
        final left = WatchMeta.minutes(
          ((1 - item.completion) * runtime).round(),
        );
        if (left.isNotEmpty) remaining = '$left left';
      }
      return WatchMetaOverlay(
        durationLabel: WatchMeta.minutes(runtime),
        remainingLabel: remaining,
      );
    }

    final show = tmdb as TmdbShow;
    final runtime = WatchMeta.episodeMinutes(show);
    final aired = WatchMeta.airedEpisodes(show);
    final watched = WatchMeta.watchedEpisodesFromHistory(item);
    final left = aired > 0 ? (aired - watched).clamp(0, aired) : 0;
    final inProgress = item.episodes.where(
      (e) => e.completion > 0 && e.completion < 1,
    );
    return WatchMetaOverlay(
      durationLabel: WatchMeta.minutes(runtime),
      remainingLabel: WatchMeta.remainingLabel(
        left: left,
        minutesEach: runtime,
        currentCompletion: inProgress.isEmpty ? 0 : inProgress.last.completion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (status == CollectionStatus.watched &&
        !isFinished(item, tmdbEpisodeCount: _episodeCount)) {
      return const SizedBox.shrink();
    }

    if (status == CollectionStatus.watching &&
        !isWatching(item, tmdbEpisodeCount: _episodeCount)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                poster,
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _progressOverlay(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _progressLabel(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(
          _lastWatched(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
