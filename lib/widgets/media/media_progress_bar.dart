import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A determinate bar for the displayed episode/movie, not the whole show.
class MediaProgressBar extends StatelessWidget {
  final MediaCardTarget? target;
  final double? progress;
  const MediaProgressBar({super.key, this.target, this.progress});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      BackendCache.continueWatching,
      BackendCache.watchHistory,
    ]),
    builder: (context, _) {
      final id = target?.tmdbId;
      final completion =
          progress ??
          (id == null
              ? null
              : WatchProgress.playbackCompletion(
                  tmdbId: id,
                  type: target!.type,
                  season: target!.season,
                  episode: target!.episode,
                  history: BackendCache.watchHistory.value,
                  nextUp: BackendCache.continueWatching.value,
                ));
      if (completion == null || !WatchProgress.isPartial(completion))
        return const SizedBox.shrink();
      final percentage = '${(completion * 100).round()}% watched';
      return IgnorePointer(
        child: Semantics(
          label: 'Playback progress',
          value: percentage,
          child: SizedBox(
            height: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: .6)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: completion,
                  child: const ColoredBox(color: Colors.pink),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
