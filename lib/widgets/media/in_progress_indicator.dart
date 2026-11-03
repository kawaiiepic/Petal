import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class InProgressIndicator extends StatelessWidget {
  final MediaCardTarget target;
  final double? localProgress;
  const InProgressIndicator({
    super.key,
    required this.target,
    this.localProgress,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      BackendCache.watchHistory,
      BackendCache.continueWatching,
    ]),
    builder: (context, _) {
      final id = target.tmdbId;
      final finished = localProgress != null && localProgress! > 0
          ? WatchProgress.isWatched(localProgress!)
          : id != null &&
                WatchProgress.titleFinished(
                  tmdbId: id,
                  type: target.type,
                  totalEpisodes: target.totalEpisodes,
                  history: BackendCache.watchHistory.value,
                );
      final active = localProgress != null && localProgress! > 0
          ? WatchProgress.isPartial(localProgress!)
          : (id != null &&
                WatchProgress.titleInProgress(
                  tmdbId: id,
                  type: target.type,
                  totalEpisodes: target.totalEpisodes,
                  history: BackendCache.watchHistory.value,
                  nextUp: BackendCache.continueWatching.value,
                ));
      if (!active && !finished) return const SizedBox.shrink();
      final label = finished ? 'Finished' : 'In progress';
      return Tooltip(
        tooltip: (_) => Text(label),
        child: Semantics(
          label: label,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xE6101018),
              shape: BoxShape.circle,
            ),
            child: Icon(
              finished ? LucideIcons.circleCheck : LucideIcons.circlePlay,
              size: 18,
              color: finished ? Colors.green : Colors.pink,
            ),
          ),
        ),
      );
    },
  );
}
