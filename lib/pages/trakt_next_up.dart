import 'package:go_router/go_router.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/api/trakt/trakt_class.dart';
import 'package:petal/api/trakt/trakt_helper.dart';
import 'package:petal/pages/catalog_item.dart';
import 'package:petal/pages/scrollable_widget.dart';
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
  late Future<List<TraktWatchedShowWithProgress>> _watchedFuture;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _watchedFuture = TraktApi.fetchWatchedShowWithProgress();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 18);
    return Column(
      spacing: 8,
      children: [
        Text('Next Ups', style: style),
        FutureBuilder(
          future: _watchedFuture,
          builder: (context, snapshot) {
            return SizedBox(
              height: 25.h,
              child: ScrollableWidget(
                controller: _controller,
                offset: -25,
                child: ListView.builder(
                  controller: _controller,
                  itemExtent: 38.w,
                  scrollDirection: Axis.horizontal,
                  key: PageStorageKey<String>('unique_key_for_this_list'),

                  itemCount: snapshot.hasData ? snapshot.data!.length : 10,
                  itemBuilder: (context, index) => snapshot.hasData
                      ? TraktNextUpItem(key: ValueKey(snapshot.data![index].watchedShow!.show.title), show: snapshot.data![index])
                      : Container(
                          color: Colors.transparent,
                          width: 300,
                          height: 250,
                          child: Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(8),
                                child: Container(color: Colors.pink.withAlpha(40)),
                              ),
                            ),
                          ),
                        ).asSkeleton(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class TraktNextUpItem extends StatefulWidget {
  final TraktWatchedShowWithProgress show;

  const TraktNextUpItem({super.key, required this.show});

  @override
  State<StatefulWidget> createState() => _TraktNextUpItem();
}

class _TraktNextUpItem extends State<TraktNextUpItem> {
  late final Future<String> _futureStill;

  @override
  void initState() {
    super.initState();
    _futureStill = TMDB.episode_still(
      widget.show.watchedShow!.show.ids.tmdb.toString(),
      widget.show.showProgress.nextEpisode!.season,
      widget.show.showProgress.nextEpisode!.number,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _futureStill,
    builder: (context, tmdbPosterSnapshot) {
      switch (tmdbPosterSnapshot.connectionState) {
        case ConnectionState.active:
        case ConnectionState.done:
          {
            if (tmdbPosterSnapshot.hasError) {
              return Text('Error: ${widget.show.watchedShow!.show.title}');
            }

            return ContextMenu(
              items: [
                MenuButton(
                  onPressed: (context) => context.push(
                    '/streams?show=${widget.show.watchedShow!.show.ids.tmdb}&s=${widget.show.showProgress.nextEpisode!.season}&e=${widget.show.showProgress.nextEpisode!.number}',
                  ),
                  child: Text('Select Source'),
                ),
                MenuButton(child: Text('View Show')),
                MenuButton(child: Text('Mark as Watched')),
              ],
              child: Column(
                spacing: 8,
                children: [
                  Expanded(
                    child: HoverableItem(
                      orientation: Orientation.landscape,
                      image: CachedNetworkImage(imageUrl: tmdbPosterSnapshot.data!, fit: BoxFit.cover),
                      onTap: () {
                        context.push(
                          '/player?show=${widget.show.watchedShow!.show.ids.tmdb}&s=${widget.show.showProgress.nextEpisode!.season}&e=${widget.show.showProgress.nextEpisode!.number}',
                        );
                      },
                    ),
                  ),
                  Text(
                    style: TextStyle(fontSize: 15.px),
                    "${widget.show.showProgress.nextEpisode!.season}x${widget.show.showProgress.nextEpisode!.number} ${widget.show.watchedShow!.show.title}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    style: TextStyle(fontSize: 15.px),
                    widget.show.showProgress.nextEpisode!.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                ],
              ),
            );

            return SizedBox(
              height: 100,
              child: Column(
                spacing: 8,
                children: [
                  ContextMenu(
                    items: [
                      MenuButton(
                        onPressed: (context) => context.push(
                          '/streams?show=${widget.show.watchedShow!.show.ids.tmdb}&s=${widget.show.showProgress.nextEpisode!.season}&e=${widget.show.showProgress.nextEpisode!.number}',
                        ),
                        child: Text('Select Source'),
                      ),
                      MenuButton(child: Text('View Show')),
                      MenuButton(child: Text('Mark as Watched')),
                    ],
                    child: HoverableItem(
                      orientation: Orientation.landscape,
                      onTap: () {
                        context.push(
                          '/player?show=${widget.show.watchedShow!.show.ids.tmdb}&s=${widget.show.showProgress.nextEpisode!.season}&e=${widget.show.showProgress.nextEpisode!.number}',
                        );
                      },
                      image: CachedNetworkImage(imageUrl: tmdbPosterSnapshot.data!, fit: BoxFit.cover),
                    ),
                  ),

                  Text(
                    style: TextStyle(fontSize: 15.px),
                    "${widget.show.showProgress.nextEpisode!.season}x${widget.show.showProgress.nextEpisode!.number} ${widget.show.watchedShow!.show.title}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    style: TextStyle(fontSize: 15.px),
                    widget.show.showProgress.nextEpisode!.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }
        case _:
          return Text('gay');
      }
    },
  );
}
