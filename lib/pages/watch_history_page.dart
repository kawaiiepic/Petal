import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/profile/profile_history_tile.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});
  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _run(() => BackendCache.fetchWatchHistory(force: true));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not update history. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    headers: const [
      AppBar(leading: [BackButton()], title: Text('Playback history')),
    ],
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 8,
            children: [
              const Text(
                'Reset accidental progress or mark an episode/movie watched. Undo restores the previous progress. Play records and play counts cannot be deleted with the current backend.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  Button.outline(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => BackendCache.fetchWatchHistory(force: true),
                          ),
                    child: const Text('Refresh'),
                  ),
                  ValueListenableBuilder(
                    valueListenable: HistoryActions.canUndo,
                    builder: (context, canUndo, _) => Button.outline(
                      onPressed: !canUndo || _busy
                          ? null
                          : () => _run(HistoryActions.undo),
                      child: const Text('Undo last progress change'),
                    ),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: BackendCache.watchHistory,
            builder: (context, items, _) {
              final sorted = [...items]
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              if (sorted.isEmpty && !_busy)
                return const Center(child: Text('No playback history yet.'));
              return ListView(
                children: [
                  for (final item in sorted)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileHistoryTile(item: item),
                            if (item.mediaType == MediaType.movie)
                              _controls(
                                item.tmdbId,
                                item.mediaType,
                                item.completion,
                              ),
                            if (item.mediaType == MediaType.show)
                              for (final episode in item.episodes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Button.ghost(
                                        onPressed: () => context.push(
                                          '/episode?tmdb=${item.tmdbId}&s=${episode.season}&e=${episode.episode}',
                                        ),
                                        child: Text(
                                          'S${episode.season} E${episode.episode}',
                                        ),
                                      ),
                                      _controls(
                                        item.tmdbId,
                                        item.mediaType,
                                        episode.completion,
                                        season: episode.season,
                                        episode: episode.episode,
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
  Widget _controls(
    int id,
    MediaType type,
    double completion, {
    int? season,
    int? episode,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('${(completion * 100).round()}%'),
      Button.outline(
        onPressed: _busy || completion == 0
            ? null
            : () => _run(
                () => HistoryActions.setProgress(
                  id,
                  type,
                  0,
                  season: season,
                  episode: episode,
                ),
              ),
        child: const Text('Reset progress'),
      ),
      Button.ghost(
        onPressed: _busy
            ? null
            : () => _run(
                () => HistoryActions.setProgress(
                  id,
                  type,
                  completion >= .9 ? 0 : 1,
                  season: season,
                  episode: episode,
                ),
              ),
        child: Text(completion >= .9 ? 'Mark unwatched' : 'Mark watched'),
      ),
    ],
  );
}
