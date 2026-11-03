import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/episode.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/utils/watch_counts.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchActivityPanel extends StatefulWidget {
  final int tmdbId;
  final MediaType mediaType;
  final TmdbShow? show;
  final int? season;
  final int? episode;

  const WatchActivityPanel({super.key, required this.tmdbId,
    required this.mediaType, this.show, this.season, this.episode});

  @override
  State<WatchActivityPanel> createState() => _WatchActivityPanelState();
}

class _WatchActivityPanelState extends State<WatchActivityPanel> {
  late Future<({List<String> aired, Episode? first})> _catalog = _load();
  bool _busy = false;

  @override
  void didUpdateWidget(covariant WatchActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tmdbId != widget.tmdbId || oldWidget.mediaType != widget.mediaType ||
        oldWidget.season != widget.season || oldWidget.episode != widget.episode ||
        oldWidget.show?.id != widget.show?.id) _catalog = _load();
  }

  Future<({List<String> aired, Episode? first})> _load() async {
    await BackendCache.fetchWatchHistory();
    final show = widget.show;
    if (show == null || widget.season != null) return (aired: <String>[], first: null);
    final seasons = show.mainSeasons.toList()
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    final keys = <String>[];
    Episode? first;
    final now = DateTime.now();
    for (final season in seasons) {
      final details = await TMDB.tvSeason(show.id, season.seasonNumber);
      final episodes = details.episodes.toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      for (final ep in episodes) {
        if (ep.airDate == null || ep.airDate!.isAfter(now)) continue;
        keys.add('${ep.seasonNumber}:${ep.episodeNumber}');
        first ??= Episode(seasonNumber: ep.seasonNumber, episodeNumber: ep.episodeNumber);
      }
    }
    return (aired: keys, first: first);
  }

  Future<void> _rewatch(Episode? first) async {
    final profile = BackendApi.profileCacheKey;
    final id = widget.tmdbId, type = widget.mediaType;
    final requestedSeason = widget.season, requestedEpisode = widget.episode;
    if (profile == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (requestedSeason != null && requestedEpisode != null) {
        await HistoryActions.rewatch(id, type,
          season: requestedSeason, episode: requestedEpisode);
      } else {
        await HistoryActions.startTitleRewatch(id, type);
      }
      if (!mounted || profile != BackendApi.profileCacheKey || widget.tmdbId != id || widget.mediaType != type) return;
      final season = requestedSeason ?? first?.seasonNumber;
      final episode = requestedEpisode ?? first?.episodeNumber;
      await context.push('/player?media=$id&p=0'
        '${season == null ? '' : '&s=$season&e=$episode'}');
      if (mounted && profile == BackendApi.profileCacheKey) {
        await BackendCache.fetchWatchHistory(force: true);
      }
    } catch (error) {
      if (mounted) AppNotifications.sendNotification(
        const Text('Could not start rewatch'), Text(HistoryActions.errorMessage(error)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _catalog,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Button(
        style: const ButtonStyle.ghost(),
        onPressed: () => setState(() => _catalog = _load()),
        child: const Text('Retry watch activity'));
      if (!snapshot.hasData) return const Text('Loading watch activity…');
      final catalog = snapshot.data!;
      return ValueListenableBuilder(
        valueListenable: BackendCache.watchHistory,
        builder: (context, history, _) {
          final counts = WatchCounts.episodes(history, widget.tmdbId);
          final isEpisode = widget.season != null && widget.episode != null;
          final total = widget.mediaType == MediaType.movie
            ? WatchCounts.movie(history, widget.tmdbId)
            : isEpisode
              ? WatchCounts.episode(history, widget.tmdbId, widget.season!, widget.episode!)
              : counts.values.fold<int>(0, (sum, count) => sum + count);
          final full = WatchCounts.fullViewings(counts, catalog.aired);
          final label = widget.mediaType == MediaType.show && !isEpisode
            ? '$total episode watches · All aired episodes watched $full ${full == 1 ? 'time' : 'times'}'
            : total == 0 ? 'Not watched yet'
            : 'Watched $total ${total == 1 ? 'time' : 'times'}';
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(label),
              if (total > 0)
                Button(
                  style: const ButtonStyle.outline(),
                  onPressed: _busy || BackendApi.profileCacheKey == null ||
                      (widget.show != null && catalog.first == null)
                    ? null : () => _rewatch(catalog.first),
                  child: Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
                    const Icon(LucideIcons.rotateCcw, size: 16),
                    Text(_busy ? 'Starting…' : 'Start rewatch'),
                  ]),
                ),
              ValueListenableBuilder(
                valueListenable: HistoryActions.canUndo,
                builder: (context, canUndo, _) => canUndo
                  ? Button(
                    style: const ButtonStyle.ghost(),
                    onPressed: _busy ? null : () async {
                      try { await HistoryActions.undo(); }
                      catch (error) {
                        AppNotifications.sendNotification(
                          const Text('Could not undo'), Text(HistoryActions.errorMessage(error)));
                      }
                    },
                    child: const Text('Undo'),
                  ) : const SizedBox.shrink(),
              ),
            ],
          );
        },
      );
    },
  );
}
