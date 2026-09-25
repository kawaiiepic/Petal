import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/router/router.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/scrollable_widget.dart';
import 'package:petal/widgets/watch_meta_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sizer/sizer.dart';

class TraktNextUp extends StatefulWidget {
  const TraktNextUp({super.key});

  @override
  State<StatefulWidget> createState() => _TraktNextUp();
}

class _TraktNextUp extends State<TraktNextUp> {
  late final ScrollController _controller;
  bool _open = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp);
    return ValueListenableBuilder(
      valueListenable: BackendCache.continueWatching,
      builder: (context, list, child) {
        if (list.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            Button(
              style: ButtonVariance.ghost,
              onPressed: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('Continue Watching', style: style, textAlign: TextAlign.center)),
                    Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16),
                  ],
                ),
              ),
            ),
            if (_open)
              SizedBox(
                height: 25.h,
                child: ScrollableWidget(
                  controller: _controller,
                  offset: -25,
                  child: ListView.builder(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    key: const PageStorageKey<String>('unique_key_for_this_list'),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final state = list[index];
                      return TraktNextUpItem(key: ValueKey('${state.mediaType}-${state.tmdbId}'), state: state);
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TraktNextUpItem extends StatefulWidget {
  final ContinueWatchingItem state;

  const TraktNextUpItem({super.key, required this.state});

  @override
  State<StatefulWidget> createState() => _TraktNextUpItem();
}

class _TraktNextUpItem extends State<TraktNextUpItem> with AutomaticKeepAliveClientMixin<TraktNextUpItem> {
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
  void didUpdateWidget(covariant TraktNextUpItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldState = oldWidget.state;
    final newState = widget.state;

    if (oldState is ShowItem && newState is ShowItem) {
      final oldNext = oldState.nextEpisode;
      final newNext = newState.nextEpisode;
      final episodeChanged = oldNext?.season != newNext?.season || oldNext?.episode != newNext?.episode;
      if (episodeChanged && newNext != null) {
        _futureEpisode = TMDB.tvEpisode(newState.tmdbId, newNext.season, newNext.episode);
      }
    } else if (oldState.tmdbId != newState.tmdbId || oldState.runtimeType != newState.runtimeType) {
      _loadFutures(newState);
    }
  }

  void _loadFutures(ContinueWatchingItem state) {
    if (state is ShowItem) {
      _futureShow = TMDB.tvShow(state.tmdbId);
      final next = state.nextEpisode;
      _futureEpisode = next == null ? null : TMDB.tvEpisode(state.tmdbId, next.season, next.episode);
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
      trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.enter)),
      child: const Text('Resume'),
      onPressed: (context) {
        final state = widget.state;
        if (state is ShowItem && state.nextEpisode != null) {
          AppRouter.appRouter.push('/player?media=${state.tmdbId}&s=${state.nextEpisode!.season}&e=${state.nextEpisode!.episode}');
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
          AppRouter.appRouter.push('/streams?show=${state.tmdbId}&s=${state.nextEpisode!.season}&e=${state.nextEpisode!.episode}');
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
          BackendApi.setProgress(state.tmdbId, state.mediaType, 1.0, season: state.nextEpisode!.season, episode: state.nextEpisode!.episode);
        } else {
          BackendApi.setProgress(state.tmdbId, state.mediaType, 1.0);
        }
      },
    ),
    MenuButton(leading: const Icon(LucideIcons.repeat2), child: const Text('Restart')),
    MenuButton(leading: const Icon(LucideIcons.bookmark), child: Text(false ? 'Remove from Watchlist' : 'Add to Watchlist')),
    const MenuDivider(),
    MenuButton(leading: const Icon(LucideIcons.delete), child: const Text('Remove from Continue Watching')),
  ];

  Widget episodeWidget(ShowItem state) {
    final next = state.nextEpisode;
    return FutureBuilder<TmdbEpisode>(
      future: _futureEpisode,
      builder: (context, snapshot) => Padding(
        padding: EdgeInsetsGeometry.fromLTRB(2.w, 8, 2.w, 8),
        child: Column(
          spacing: 8,
          children: [
            Expanded(
              child: HoverableItem(
                orientation: Orientation.landscape,
                contextItems: contextItems(),
                onTap: () {
                  if (next == null) return;
                  context.push(
                    '/player?media=${state.tmdbId}&s=${next.season}&e=${next.episode}${next.completion > 0.0 && next.completion < 1.0 ? '&p=${next.completion}' : ''}',
                  );
                },
                image: snapshot.hasData
                    ? CachedNetworkImage(imageUrl: snapshot.data!.stillUrl ?? '', fit: BoxFit.fitHeight, height: 20)
                    : Avatar(initials: '', borderRadius: 12).asSkeleton(),
                extraWidget: Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: FutureBuilder<TmdbShow>(
                    future: _futureShow,
                    builder: (context, showSnap) {
                      final episode = snapshot.data;
                      final show = showSnap.data;
                      final runtime = WatchMeta.episodeMinutes(show, episodeRuntime: episode?.runtime);
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
              ),
            ),
            SizedBox(
              height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<TmdbShow>(
                    future: _futureShow,
                    builder: (context, snap2) => Text(
                      !snap2.hasData ? 'Loading...' : snap2.data!.name,
                      style: TextStyle(fontSize: 15.px, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).asSkeleton(snapshot: snap2),
                  ),
                  Text(
                    next == null
                        ? 'Loading...'
                        : snapshot.hasData
                            ? 'S${next.season} \u00b7 E${next.episode} - ${snapshot.data!.name}'
                            : 'S${next.season} \u00b7 E${next.episode}',
                    style: TextStyle(fontSize: 13.px, color: Colors.white.withValues(alpha: 0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).asSkeleton(snapshot: snapshot),
    );
  }

  Widget movieWidget(MovieItem state) => FutureBuilder<TmdbMovie>(
    future: _futureMovie,
    builder: (context, snapshot) => Padding(
      padding: EdgeInsetsGeometry.fromLTRB(2.w, 8, 2.w, 8),
      child: Column(
        spacing: 8,
        children: [
          Expanded(
            child: HoverableItem(
              orientation: Orientation.landscape,
              contextItems: contextItems(),
              onTap: () {
                context.push('/player?media=${state.tmdbId}${state.completion > 0.0 && state.completion < 1.0 ? '&p=${state.completion}' : ''}');
              },
              image: snapshot.hasData
                  ? CachedNetworkImage(imageUrl: snapshot.data!.images!.backdrops.first.url, fit: BoxFit.cover)
                  : Avatar(initials: '', borderRadius: 12).asSkeleton(),
              extraWidget: Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: WatchMetaOverlay(
                  durationLabel: WatchMeta.minutes(snapshot.data?.runtime ?? 0),
                  remainingLabel: () {
                    final runtime = snapshot.data?.runtime ?? 0;
                    if (runtime <= 0 || state.completion <= 0 || state.completion >= 1) return null;
                    final left = ((1 - state.completion) * runtime).round();
                    final label = WatchMeta.minutes(left);
                    return label.isEmpty ? null : '$label left';
                  }(),
                ),
              ),
            ),
          ),
          SizedBox(
            height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
            child: Text(
              !snapshot.hasData ? 'Loading...' : snapshot.data!.title,
              style: TextStyle(fontSize: 15.px),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).asSkeleton(snapshot: snapshot),
  );
}
