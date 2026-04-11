import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/pages/catalog_item.dart';
import 'package:blssmpetal/pages/scrollable_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
    print("Rebuilding NextUPp");
    final style = TextStyle(fontSize: 18);
    return Column(
      spacing: 8,
      children: [
        Text('Next Up', style: style),
        FutureBuilder(
          future: _watchedFuture,
          builder: (context, snapshot) {
            return SizedBox(
              height: 250,
              child: ScrollableWidget(
                controller: _controller,
                child: ListView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  key: PageStorageKey<String>('unique_key_for_this_list'),

                  itemCount: snapshot.hasData ? snapshot.data!.length : 10,
                  itemBuilder: (context, index) => snapshot.hasData
                      ? TraktNextUpItem(key: ValueKey(snapshot.data![index].watchedShow!.show.title), show: snapshot.data![index])
                      : Container(
                          color: Colors.transparent,
                          width: 400,
                          height: 190,
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

  // @override
  // Widget build(BuildContext context) {
  //   final style = TextStyle(fontSize: 18);
  //   return FutureBuilder(
  //     future: ApiCache.getTraktWatched(),
  //     builder: (context, watchedSnapshot) {
  //       switch (watchedSnapshot.connectionState) {
  //         case ConnectionState.active:
  //         case ConnectionState.done:
  //           {
  //             final traktWatched = watchedSnapshot.data!;

  //             return Column(
  //               spacing: 8,
  //               children: [
  //                 Text('Next Up', style: style),
  //                 SizedBox(
  //                   height: 250,
  //                   child: ScrollableWidget(
  //                     controller: _controller,
  //                     child: ListView.builder(
  //                       controller: _controller,
  //                       scrollDirection: Axis.horizontal,
  //                       itemCount: traktWatched.length,
  //                       itemBuilder: (context, index) {
  //                         final watchedItem = traktWatched[index];
  //                         return TraktNextUpItem(show: watchedItem);
  //                       },
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           }
  //         case _:
  //           return SizedBox();
  //       }
  //     },
  //   );
  // }
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

            print("Reloading Thingyy.");

            return SizedBox(
              width: 400,
              child: Column(
                spacing: 8,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://wallpapers-clan.com/wp-content/uploads/2025/05/pensive-anime-girl-neon-lights-desktop-wallpaper-preview.jpg',
                    width: 100,
                  ),

                  // HoverableItem(
                  //   image: CachedNetworkImage(imageUrl: tmdbPosterSnapshot.data!, fit: BoxFit.cover),
                  // ),
                  Text(
                    "${widget.show.showProgress.nextEpisode!.season}x${widget.show.showProgress.nextEpisode!.number} ${widget.show.watchedShow!.show.title}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(widget.show.showProgress.nextEpisode!.title!, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
            // return MouseRegion(
            //   onEnter: (event) => setState(() {
            //     _isHovering = true;
            //   }),
            //   onExit: (event) => setState(() {
            //     _isHovering = false;
            //   }),
            //   child: GestureDetector(
            //     onTap: () => context.push(
            //       '/player?show=${widget.show.watchedShow!.show.ids.tmdb}&s=${widget.show.showProgress.nextEpisode!.season}&e=${widget.show.showProgress.nextEpisode!.number}',
            //     ),
            //     child: Column(
            //       spacing: 8,
            //       children: [
            //         Container(
            //           color: Colors.transparent,
            //           width: 400,
            //           height: 190,
            //           child: Padding(
            //             padding: const EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
            //             child: Container(
            //               decoration: BoxDecoration(
            //                 border: Border.all(color: _isHovering ? Colors.white : Colors.transparent),
            //                 borderRadius: BorderRadius.circular(8.0),
            //               ),
            //               child: ClipRRect(
            //                 borderRadius: BorderRadiusGeometry.circular(8),
            //                 child: AnimatedScale(
            //                   scale: _isHovering ? 1.1 : 1,
            //                   duration: const Duration(milliseconds: 300),
            //                   child: CachedNetworkImage(imageUrl: tmdbPosterSnapshot.data!, fit: BoxFit.cover),
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),

            //         Text(
            //           "${widget.show.showProgress.nextEpisode!.season}x${widget.show.showProgress.nextEpisode!.number} ${widget.show.watchedShow!.show.title}",
            //           maxLines: 1,
            //           overflow: TextOverflow.ellipsis,
            //         ),

            //         Text(widget.show.showProgress.nextEpisode!.title!, maxLines: 1, overflow: TextOverflow.ellipsis),
            //       ],
            //     ),
            //   ),
            // );
          }
        case _:
          return Text('gay');
      }
    },
  );
}
