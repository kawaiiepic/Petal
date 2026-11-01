import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/home/continue_watching_card.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/media_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OnDeckShelf extends StatefulWidget {
  const OnDeckShelf({super.key});

  @override
  State<OnDeckShelf> createState() => _OnDeckShelfState();
}

class _OnDeckShelfState extends State<OnDeckShelf> {
  @override
  void initState() {
    super.initState();
    _onAuth();
    BackendApi.authState.addListener(_onAuth);
  }

  void _onAuth() {
    if (BackendApi.authState.selectedProfile != null) {
      BackendCache.fetchContinueWatching();
    }
  }

  @override
  void dispose() {
    BackendApi.authState.removeListener(_onAuth);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, _) {
        // Prioritize "nextUp" - recently watched items with next episode available
        final nextUp = list.where(_nextUp).map((item) => item).toList()
          ..sort((a, b) {
            // Sort by most recently watched first (higher completion in recent watches)
            double? maxAProgress;
            double? maxBProgress;
            if (a is ShowItem && a.seasons.isNotEmpty) {
              for (final season in a.seasons) {
                for (final episode in season.episodes) {
                  if (episode.completion > 0) {
                    maxAProgress = ((maxAProgress ?? 0.0) > episode.completion
                        ? maxAProgress
                        : episode.completion);
                  }
                }
              }
            } else if (a is MovieItem) {
              maxAProgress = a.completion;
            } else {
              maxAProgress = 0.0;
            }

            if (b is ShowItem && b.seasons.isNotEmpty) {
              for (final season in b.seasons) {
                for (final episode in season.episodes) {
                  if (episode.completion > 0) {
                    maxBProgress = ((maxBProgress ?? 0.0) > episode.completion
                        ? maxBProgress
                        : episode.completion);
                  }
                }
              }
            } else if (b is MovieItem) {
              maxBProgress = b.completion;
            } else {
              maxBProgress = 0.0;
            }

            // Use negative value so higher completion comes first
            return (maxAProgress ?? 0.0).compareTo(maxBProgress ?? 0.0);
          })
          ..take(12);

        // Fall back to all on deck if nextUp is empty
        final onDeck = nextUp.isEmpty
            ? list.where(_onDeck).take(12).toList()
            : nextUp;
        if (onDeck.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'On deck',
          child: MediaShelf(
            orientation: Orientation.landscape,
            itemCount: onDeck.length,
            itemBuilder: (context, index) {
              final state = onDeck[index];
              return ContinueWatchingCard(
                key: ValueKey('deck-${state.mediaType}-${state.tmdbId}'),
                state: state,
              );
            },
          ),
        );
      },
    );
  }
}

bool _isRecentlyWatched(ContinueWatchingItem item) {
  if (item is ShowItem) {
    // Check if any season has episodes with partial completion
    for (final season in item.seasons) {
      for (final episode in season.episodes) {
        if (WatchProgress.isPartial(episode.completion)) {
          return true;
        }
      }
    }
    return false;
  }
  if (item is MovieItem) {
    return WatchProgress.isPartial(item.completion);
  }
  return false;
}

bool _onDeck(ContinueWatchingItem item) {
  if (item is ShowItem) {
    final next = item.nextEpisode;
    // Only include shows that have a next episode to watch
    return next != null && next.completion <= 0;
  }
  return false;
}

bool _nextUp(ContinueWatchingItem item) {
  if (item is ShowItem) {
    final next = item.nextEpisode;
    // Must have a next episode to watch
    if (next == null || WatchProgress.isWatched(next.completion)) return false;
    // Must be recently watched (has partial completion somewhere)
    return _isRecentlyWatched(item);
  }
  if (item is MovieItem) {
    // For movies, check if partially watched
    return WatchProgress.isPartial(item.completion);
  }
  return false;
}
