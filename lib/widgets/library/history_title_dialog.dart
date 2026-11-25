import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/group_watch_history.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HistoryTitleDialog extends StatefulWidget {
  const HistoryTitleDialog({
    super.key,
    required this.tmdbId,
    required this.type,
    required this.title,
  });

  final int tmdbId;
  final MediaType type;
  final String title;

  @override
  State<HistoryTitleDialog> createState() => _HistoryTitleDialogState();
}

class _HistoryTitleDialogState extends State<HistoryTitleDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = HistoryActions.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _open(String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final isShow = widget.type == MediaType.show;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 540,
        height: MediaQuery.sizeOf(context).height * .52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error case final error?) Text(error),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: BackendCache.watchHistory,
                builder: (context, history, _) {
                  final item = groupWatchHistory([
                    for (final item in history)
                      if (item.tmdbId == widget.tmdbId &&
                          item.mediaType == widget.type)
                        item,
                  ]).firstOrNull;
                  if (item == null || (isShow && item.episodes.isEmpty)) {
                    return const Center(
                      child: Text('No playback history for this title.'),
                    );
                  }
                  if (!isShow) {
                    return ListView(
                      primary: false,
                      children: [
                        _controls(item.completion, item.watches, item.plays),
                      ],
                    );
                  }
                  final episodes = [...item.episodes]
                    ..sort((a, b) {
                      final season = a.season.compareTo(b.season);
                      return season == 0
                          ? a.episode.compareTo(b.episode)
                          : season;
                    });
                  return ListView.separated(
                    primary: false,
                    itemCount: episodes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      final season = episode.season;
                      final number = episode.episode;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 8,
                        children: [
                          if (index == 0 ||
                              episodes[index - 1].season != season)
                            Semantics(
                              header: true,
                              child: Text(
                                season == 0 ? 'Specials' : 'Season $season',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          LibraryPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 6,
                              children: [
                                PetalButton.ghost(
                                  onPressed: () => _open(
                                    '/episode?tmdb=${widget.tmdbId}&s=$season&e=$number',
                                  ),
                                  child: Text('Episode $number'),
                                ),
                                _controls(
                                  episode.completion,
                                  episode.watches,
                                  episode.plays,
                                  season: season,
                                  episode: number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        PetalButton.secondary(
          onPressed: () =>
              _open('/${isShow ? 'series' : 'movie'}?tmdb=${widget.tmdbId}'),
          child: Text(isShow ? 'View show' : 'View movie'),
        ),
        PetalButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _controls(
    double completion,
    List<DateTime> watches,
    int plays, {
    int? season,
    int? episode,
  }) {
    final watched = WatchProgress.isWatched(completion);
    Future<void> setProgress(double value) => HistoryActions.setProgress(
      widget.tmdbId,
      widget.type,
      value,
      season: season,
      episode: episode,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${(completion * 100).round()}% · $plays ${plays == 1 ? 'play' : 'plays'}',
        ),
        PetalButton.outline(
          onPressed: _busy || (completion == 0 && watches.isEmpty && plays == 0)
              ? null
              : () => _run(() => setProgress(0)),
          child: const Text('Reset progress'),
        ),
        PetalButton.ghost(
          onPressed: _busy
              ? null
              : () => _run(() => setProgress(watched ? 0 : 1)),
          child: Text(watched ? 'Mark unwatched' : 'Mark watched'),
        ),
        PetalButton.outline(
          onPressed: _busy
              ? null
              : () => _run(
                  () => HistoryActions.remove(
                    widget.tmdbId,
                    widget.type,
                    season: season,
                    episode: episode,
                  ),
                ),
          child: const Text('Remove from history'),
        ),
        for (var index = 0; index < watches.length; index++)
          PetalButton.ghost(
            onPressed: _busy
                ? null
                : () => _run(
                    () => HistoryActions.deleteWatch(
                      widget.tmdbId,
                      widget.type,
                      index,
                      watches[index],
                      season: season,
                      episode: episode,
                    ),
                  ),
            child: Text(
              'Remove play ${index + 1} · ${watches[index].toLocal().toString().split('.').first}',
            ),
          ),
      ],
    );
  }
}
