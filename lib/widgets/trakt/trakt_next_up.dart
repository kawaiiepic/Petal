import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/api/trakt/backend_api.dart';
import 'package:petal/api/trakt/backend_cache.dart';
import 'package:petal/models/media_state.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/scrollable_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();

    BackendApi.authState.addListener(() {
      setState(() {
        BackendCache.fetchContinueWatching();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: Device.screenType == ScreenType.desktop ? 12.sp : 16.sp);
    return Column(
      spacing: 8,
      children: [
        Text('Continue Watching', style: style),
        ValueListenableBuilder(
          valueListenable: BackendCache.continueWatching,
          builder: (context, list, child) {
            if (list.isEmpty) {
              return Text('No items to continue watching');
            } else {
              return SizedBox(
                height: 25.h,
                child: ScrollableWidget(
                  controller: _controller,
                  offset: -25,
                  child: ListView.builder(
                    controller: _controller,
                    // itemExtent: 38.w,
                    scrollDirection: Axis.horizontal,
                    key: const PageStorageKey<String>('unique_key_for_this_list'),

                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final state = list[index];
                      return TraktNextUpItem(key: ValueKey(state.tmdbId), state: state);
                    },
                  ),
                ),
              );
            }
          },
        ),
      ],
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
    final state = widget.state;

    if (state is ShowItem) {
      _futureShow = TMDB.tvShow(state.tmdbId);
      _futureEpisode = TMDB.tvEpisode(state.tmdbId, state.nextEpisode!.season, state.nextEpisode!.episode);
    } else {
      _futureMovie = TMDB.movie(state.tmdbId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (state is ShowItem) {
      return episodeWidget(state);
    } else if (state is MovieItem) {
      return movieWidget(state);
    }

    return Container();
  }

  List<MenuItem> contextItems() => [
    MenuButton(
      leading: const Icon(Icons.play_arrow_rounded),
      trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.enter)),
      child: const Text('Resume'),
    ),
    MenuButton(
      leading: const Icon(Icons.dns_outlined),
      trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
      child: const Text('Select Source'),
    ),
    const MenuDivider(),
    MenuButton(leading: const Icon(Icons.info_outline_rounded), child: const Text('More Info')),
    const MenuDivider(),
    MenuButton(leading: const Icon(Icons.check_rounded), child: const Text('Mark as Watched')),
    MenuButton(leading: const Icon(Icons.replay_rounded), child: const Text('Restart')),
    MenuButton(leading: const Icon(Icons.bookmark_outline_rounded), child: Text(true ? 'Remove from Watchlist' : 'Add to Watchlist')),
    const MenuDivider(),
    MenuButton(leading: const Icon(Icons.remove_circle_outline_rounded), child: const Text('Remove from Continue Watching')),
  ];

  Widget episodeWidget(ShowItem state) => FutureBuilder(
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
                context.push('/player?show=${state.tmdbId}&s=${state.nextEpisode!.season}&e=${state.nextEpisode!.episode}');
              },
              image: snapshot.hasData
                  ? CachedNetworkImage(imageUrl: snapshot.data!.stillUrl!, fit: BoxFit.fitHeight, height: 20)
                  : Avatar(initials: '', borderRadius: 12).asSkeleton(),
              extraWidget: state.nextEpisode!.completion > 0.0 && state.nextEpisode!.completion < 1.0
                  ? Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: SizedBox(
                        child: LinearProgressIndicator(value: state.nextEpisode!.completion, minHeight: 5, borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : null,
            ),
          ),

          SizedBox(
            height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
            child: Column(
              children: [
                FutureBuilder(
                  future: _futureShow,
                  builder: (context, snap2) => Text(
                    !snap2.hasData ? "00x00 Loading..." : "${state.nextEpisode!.season}x${state.nextEpisode!.episode} ${snap2.data!.name}",
                    style: TextStyle(fontSize: 15.px),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).asSkeleton(snapshot: snap2),
                ),

                Text(
                  !snapshot.hasData ? "Loading..." : snapshot.data!.name,
                  style: TextStyle(fontSize: 15.px),
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

  Widget movieWidget(MovieItem state) => FutureBuilder(
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
                context.push('/player?movie=${state.tmdbId}');
              },
              image: snapshot.hasData
                  ? CachedNetworkImage(imageUrl: snapshot.data!.images!.backdrops.first.url, fit: BoxFit.cover)
                  : Avatar(initials: '', borderRadius: 12).asSkeleton(),
              extraWidget: state.completion > 0.0 && state.completion < 1.0
                  ? Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: SizedBox(
                        child: LinearProgressIndicator(value: state.completion, minHeight: 5, borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  : null,
            ),
          ),

          SizedBox(
            height: Device.screenType == ScreenType.desktop ? 5.h : 6.h,
            child: Text(
              !snapshot.hasData ? "Loading..." : snapshot.data!.title,
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
