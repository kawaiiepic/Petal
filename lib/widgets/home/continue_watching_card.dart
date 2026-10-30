import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/backend/backend_api.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/tmdb/tmdb_episode.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/models/watch_history/continue_watching_item.dart';
import 'package:petal/models/watch_history/movie_item.dart';
import 'package:petal/models/watch_history/show_item.dart';
import 'package:petal/router/app_router.dart';
import 'package:petal/utils/watch_meta.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ContinueWatchingCard extends StatefulWidget {
  final ContinueWatchingItem state;

  const ContinueWatchingCard({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<ContinueWatchingCard>
    with AutomaticKeepAliveClientMixin<ContinueWatchingCard> {
  Future<TmdbEpisode>? _futureEpisode;
  Future<TmdbShow>? _futureShow;
  Future<TmdbMovie>? _futureMovie;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFutures(widget.state);
  }

  @override
  void didUpdateWidget(covariant ContinueWatchingCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldState = oldWidget.state;
    final newState = widget.state;

    if (oldState is ShowItem && newState is ShowItem) {
      final oldNext = oldState.nextEpisode;
      final newNext = newState.nextEpisode;
      final episodeChanged =
          oldNext?.season != newNext?.season ||
          oldNext?.episode != newNext?.episode;
      if (episodeChanged && newNext != null) {
        _futureEpisode = TMDB.tvEpisode(
          newState.tmdbId,
          newNext.season,
          newNext.episode,
        );
      }
    } else if (oldState.tmdbId != newState.tmdbId ||
        oldState.runtimeType != newState.runtimeType) {
      _loadFutures(newState);
    }
  }

  void _loadFutures(ContinueWatchingItem state) {
    if (state is ShowItem) {
      _futureShow = TMDB.tvShow(state.tmdbId);
      final next = state.nextEpisode;
      _futureEpisode = next == null
          ? null
          : TMDB.tvEpisode(state.tmdbId, next.season, next.episode);
    } else {
      _futureMovie = TMDB.movie(state.tmdbId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = widget.state;
    if (state is ShowItem) return episodeWidget(state);
    if (state is MovieItem) return movieWidget(state);
    return const SizedBox.shrink();
  }

  List<MenuItem> contextItems() => [
    MenuButton(
      leading: const Icon(LucideIcons.play),
      trailing: const MenuShortcut(
        activator: SingleActivator(LogicalKeyboardKey.enter),
      ),
      child: const Text('Resume'),
      onPressed: (context) {
        final state = widget.state;
        if (state is ShowItem && state.nextEpisode != null) {
          AppRouter.appRouter.push(
            '/player?media=${state.tmdbId}&s=${state.nextEpisode!.season}&e=${state.nextEpisode!.episode}',
          );
        } else {
          AppRouter.appRouter.push('/player?media=${state.tmdbId}');
        }
      },
    ),
    MenuButton(
      leading: const Icon(LucideIcons.server),
      child: const Text('Select Source'),
      onPressed: (context) {
        final state = widget.state;
        if (state is ShowItem && state.nextEpisode != null) {
          AppRouter.appRouter.push(
            '/streams?show=${state.tmdbId}&s=${state.nextEpisode!.season}&e=${state.nextEpisode!.episode}',
          );
        } else {
          AppRouter.appRouter.push('/streams?movie=${state.tmdbId}');
        }
      },
    ),
    const MenuDivider(),
    MenuButton(
      leading: const Icon(LucideIcons.info),
      child: const Text('More Info'),
      onPressed: (context) async {
        final state = widget.state;
        if (state is ShowItem) {
          AppRouter.appRouter.push('/series?tmdb=${state.tmdbId}');
        } else {
          AppRouter.appRouter.push('/movie?tmdb=${state.tmdbId}');
        }
      },
    ),
    const MenuDivider(),
    MenuButton(
      leading: const Icon(LucideIcons.check),
      child: const Text('Mark as Watched'),
      onPressed: (context) {
        final state = widget.state;
        if (state is ShowItem && state.nextEpisode != null) {
          BackendApi.setProgress(
            state.tmdbId,
            state.mediaType,
            1.0,
            season: state.nextEpisode!.season,
            episode: state.nextEpisode!.episode,
          );
        } else {
          BackendApi.setProgress(state.tmdbId, state.mediaType, 1.0);
        }
      },
    ),
    MenuButton(
      leading: const Icon(LucideIcons.repeat2),
      child: const Text('Restart'),
    ),
    MenuButton(
      leading: const Icon(LucideIcons.bookmark),
      child: Text(false ? 'Remove from Watchlist' : 'Add to Watchlist'),
    ),
    const MenuDivider(),
    MenuButton(
      leading: const Icon(LucideIcons.delete),
      child: const Text('Remove from Continue Watching'),
    ),
  ];

  Widget episodeWidget(ShowItem state) {
    final next = state.nextEpisode;
    return FutureBuilder<TmdbEpisode>(
      future: _futureEpisode,
      builder: (context, snapshot) => MediaCard(
        orientation: Orientation.landscape,
        contextItems: contextItems(),
        onTap: () {
          if (next == null) return;
          context.push(
            '/player?media=${state.tmdbId}&s=${next.season}&e=${next.episode}${next.completion > 0.0 && next.completion < 1.0 ? '&p=${next.completion}' : ''}',
          );
        },
        imageUrl: snapshot.data?.stillUrl,
        label: snapshot.data?.name,
        overlay: Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: FutureBuilder<TmdbShow>(
            future: _futureShow,
            builder: (context, showSnap) {
              final episode = snapshot.data;
              final show = showSnap.data;
              final runtime = WatchMeta.episodeMinutes(
                show,
                episodeRuntime: episode?.runtime,
              );
              final aired = show == null ? 0 : WatchMeta.airedEpisodes(show);
              final watched = WatchMeta.watchedEpisodesFromShow(state);
              final left = aired > 0 ? (aired - watched).clamp(0, aired) : 0;
              return WatchMetaOverlay(
                durationLabel: WatchMeta.minutes(runtime),
                remainingLabel: WatchMeta.remainingLabel(
                  left: left,
                  minutesEach: runtime,
                  currentCompletion: next?.completion ?? 0,
                ),
              );
            },
          ),
        ),
      ).asSkeleton(snapshot: snapshot),
    );
  }

  Widget movieWidget(MovieItem state) => FutureBuilder<TmdbMovie>(
    future: _futureMovie,
    builder: (context, snapshot) => MediaCard(
      orientation: Orientation.landscape,
      contextItems: contextItems(),
      onTap: () {
        context.push(
          '/player?media=${state.tmdbId}${state.completion > 0.0 && state.completion < 1.0 ? '&p=${state.completion}' : ''}',
        );
      },
      imageUrl: snapshot.data?.images?.backdrops.firstOrNull?.url,
      label: snapshot.data?.title,
      overlay: Positioned(
        left: 8,
        right: 8,
        bottom: 8,
        child: WatchMetaOverlay(
          durationLabel: WatchMeta.minutes(snapshot.data?.runtime ?? 0),
          remainingLabel: () {
            final runtime = snapshot.data?.runtime ?? 0;
            if (runtime <= 0 || state.completion <= 0 || state.completion >= 1)
              return null;
            final left = ((1 - state.completion) * runtime).round();
            final label = WatchMeta.minutes(left);
            return label.isEmpty ? null : '$label left';
          }(),
        ),
      ),
    ).asSkeleton(snapshot: snapshot),
  );
}
