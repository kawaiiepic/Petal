import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/history_actions.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/app_notifications.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Shared episode actions for overview playback and season episode rows.
class EpisodeActionMenu extends StatefulWidget {
  final int tmdbId, season, episode;
  final Widget Function(BuildContext, bool, bool, VoidCallback) builder;
  const EpisodeActionMenu({super.key, required this.tmdbId,
    required this.season, required this.episode, required this.builder});

  @override
  State<EpisodeActionMenu> createState() => _EpisodeActionMenuState();
}

class _EpisodeActionMenuState extends State<EpisodeActionMenu> {
  bool _busy = false;

  double get _completion =>
      UserLibrary.pendingCompletion(widget.tmdbId, MediaType.show) ??
      WatchProgress.playbackCompletion(
        tmdbId: widget.tmdbId, type: MediaType.show,
        season: widget.season, episode: widget.episode,
        history: BackendCache.watchHistory.value,
        nextUp: BackendCache.continueWatching.value,
      ) ?? 0;

  Future<void> _run({bool play = false, bool rewatch = false,
      double? completion}) async {
    final profile = BackendApi.profileCacheKey;
    if (_busy || profile == null) return;
    final id = widget.tmdbId, season = widget.season, episode = widget.episode;
    final resume = _completion;
    setState(() => _busy = true);
    try {
      if (rewatch) {
        await HistoryActions.rewatch(id, MediaType.show,
          season: season, episode: episode);
      } else if (completion != null) {
        await HistoryActions.setProgress(id, MediaType.show, completion,
          season: season, episode: episode);
      }
      if (!mounted || profile != BackendApi.profileCacheKey ||
          id != widget.tmdbId || season != widget.season ||
          episode != widget.episode) return;
      if (play) {
        await context.push('/player?media=$id&s=$season&e=$episode&p=${rewatch ? 0 : WatchProgress.isPartial(resume) ? resume : 0}');
      }
    } catch (error) {
      if (mounted) AppNotifications.sendNotification(
        const Text('Could not update episode'),
        Text(HistoryActions.errorMessage(error)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      BackendCache.watchHistory, BackendCache.continueWatching,
      UserLibrary.pendingWatched,
    ]),
    builder: (context, _) {
      final watched = WatchProgress.isWatched(_completion);
      final disabled = _busy || BackendApi.profileCacheKey == null ||
          UserLibrary.isChangingWatched(widget.tmdbId, MediaType.show);
      void play() => _run(play: true, rewatch: watched);
      return ContextMenu(
        items: [
          MenuButton(
            leading: const Icon(LucideIcons.play),
            onPressed: disabled ? null : (_) => play(),
            child: Text(watched ? 'Rewatch' : 'Play'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.rotateCcw),
            onPressed: disabled ? null : (_) => _run(play: true, rewatch: true),
            child: const Text('Start rewatch'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.check),
            onPressed: disabled ? null :
                (_) => _run(completion: watched ? 0 : 1),
            child: Text(_busy ? 'Saving…' :
                watched ? 'Mark as unwatched' : 'Mark as watched'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.server),
            onPressed: (_) => context.push(
              '/streams?show=${widget.tmdbId}&s=${widget.season}&e=${widget.episode}'),
            child: const Text('Select source'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.download),
            onPressed: (_) => context.push(
              '/streams?show=${widget.tmdbId}&s=${widget.season}&e=${widget.episode}&download=1'),
            child: const Text('Download'),
          ),
        ],
        child: widget.builder(context, watched, disabled, play),
      );
    },
  );
}
