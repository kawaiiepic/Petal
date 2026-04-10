import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/trakt_next_up.dart';
import 'package:flutter/material.dart';

typedef ItemHoverCallback = void Function(CatalogItem? item, String? background);

class NextUpRow extends StatefulWidget {
  const NextUpRow({super.key});

  @override
  State<NextUpRow> createState() => _NextUpRowState();
}

class _NextUpRowState extends State<NextUpRow> {
  @override
  Widget build(BuildContext context) {
    print("Rebuilding NextUpRow");
    return SliverToBoxAdapter(
      child: Column(children: const [TraktNextUp(key: ValueKey("traktNextUp"))]),
    );

    // return Column(
    //   spacing: 8,
    //   children: [
    //     Text('Next Up'),
    //     FutureBuilder(
    //       future: _nextUpFuture,
    //       builder: (context, snapshot) {
    //         final data = snapshot.data ?? [];
    //         final itemCount = snapshot.hasData ? data.length : 30;

    //         final radius = BorderRadius.circular(8);

    //         final loadingInk = Ink(
    //           decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withValues(alpha: 0.3)),
    //         );

    //         print("Rebuilding Next Up inside");

    //         return MouseRegion(
    //           onEnter: (_) => setState(() => _isHovering = true),
    //           onExit: (_) => setState(() => _isHovering = false),
    //           cursor: SystemMouseCursors.click,
    //           child: SizedBox(
    //             height: 180,
    //             child: Stack(
    //               children: [
    //                 ListView.builder(
    //                   shrinkWrap: false,
    //                   // physics: NeverScrollableScrollPhysics(),
    //                   scrollDirection: Axis.horizontal,
    //                   controller: _controller,
    //                   itemCount: itemCount,
    //                   itemBuilder: (context, index) {
    //                     final isLoading = !snapshot.hasData;
    //                     final show = !isLoading ? snapshot.data![index] : null;

    //                     print("Rebuilding ListView");
    //                     return Padding(
    //                       padding: const EdgeInsets.symmetric(horizontal: 4),
    //                       child: SizedBox(
    //                         width: 200,
    //                         child: Column(
    //                           children: [
    //                             AspectRatio(
    //                               aspectRatio: 16 / 9,
    //                               child: isLoading
    //                                   ? InkWell(borderRadius: BorderRadius.circular(8), onTap: () {}, child: loadingInk)
    //                                   : Tooltip(
    //                                       message: show!.watchedShow!.show.title,
    //                                       child: InkWell(
    //                                         onTap: () {
    //                                           Navigator.push(context, MaterialPageRoute(builder: (_) => EpisodeOverview(item: show, selectedEpisode: null)));
    //                                         },
    //                                         child: StillPoster(
    //                                           key: ValueKey(
    //                                             "${show.watchedShow!.show.ids.tmdb}_${show.showProgress.nextEpisode!.season}_${show.showProgress.nextEpisode!.number}",
    //                                           ),
    //                                           tmdb: show.watchedShow!.show.ids.tmdb.toString(),
    //                                           season: show.showProgress.nextEpisode!.season,
    //                                           episode: show.showProgress.nextEpisode!.number,
    //                                         ),
    //                                       ),
    //                                     ),
    //                             ),

    //                             !isLoading
    //                                 ? Column(
    //                                     children: [
    //                                       Text(
    //                                         "${show!.showProgress.nextEpisode!.season}x${show.showProgress.nextEpisode!.number} ${show.showProgress.nextEpisode!.title}",
    //                                         maxLines: 1,
    //                                         overflow: TextOverflow.ellipsis,
    //                                       ),

    //                                       Text(show.watchedShow!.show.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    //                                     ],
    //                                   )
    //                                 : Container(),
    //                           ],
    //                         ),
    //                       ),
    //                     );
    //                   },
    //                 ),
    //               ],
    //             ),
    //           ),
    //         );
    //       },
    //     ),
    //   ],
    // );
  }
}
