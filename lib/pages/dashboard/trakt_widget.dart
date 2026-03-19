import 'dart:typed_data';

import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/pages/dashboard/dashboard.dart';
import 'package:blssmpetal/pages/dashboard/trakt/still.dart';
import 'package:blssmpetal/pages/episode_overview.dart';
import 'package:blssmpetal/pages/overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef ItemHoverCallback = void Function(CatalogItem? item, String? background);

class NextUpRow extends StatefulWidget {

  const NextUpRow({super.key});

  @override
  State<NextUpRow> createState() => _NextUpRowState();
}

class _NextUpRowState extends State<NextUpRow> {
  final ScrollController _controller = ScrollController();
  List<String?> _posterUrls = [];
  bool _isLoading = true;

  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isHovering = false;
  int _hoverIndex = 0;
  late final Future _nextUpFuture;

  @override
  void initState() {
    _nextUpFuture = TraktApi.fetchWatchedShowWithProgress();
    super.initState();
    // _loadPosters();
    _controller.addListener(_updateArrows);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Rebuilding Next Up");
    return Column(
      spacing: 8,
      children: [
        Text('Next Up'),
        FutureBuilder(
          future: _nextUpFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ?? [];
            final itemCount = snapshot.hasData ? data.length : 30;

            final radius = BorderRadius.circular(8);

            final loadingInk = Ink(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withValues(alpha: 0.3)),
            );

            print("Rebuilding Next Up inside");

            return MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                height: 180,
                child: Stack(
                  children: [
                    ListView.builder(
                      shrinkWrap: false,
                      // physics: NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      controller: _controller,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        final isLoading = !snapshot.hasData;
                        final show = !isLoading ? snapshot.data![index] : null;

                        print("Rebuilding ListView");
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 200,
                            child: Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: isLoading
                                      ? InkWell(borderRadius: BorderRadius.circular(8), onTap: () {}, child: loadingInk)
                                      : Tooltip(
                                          message: show!.watchedShow!.show.title,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => EpisodeOverview(item: show, selectedEpisode: null)));
                                            },
                                            child: StillPoster(
                                              key: ValueKey(
                                                "${show.watchedShow!.show.ids.tmdb}_${show.showProgress.nextEpisode!.season}_${show.showProgress.nextEpisode!.number}",
                                              ),
                                              tmdb: show.watchedShow!.show.ids.tmdb.toString(),
                                              season: show.showProgress.nextEpisode!.season,
                                              episode: show.showProgress.nextEpisode!.number,
                                            ),
                                          ),
                                        ),
                                ),

                                !isLoading
                                    ? Column(
                                        children: [
                                          Text(
                                            "${show!.showProgress.nextEpisode!.season}x${show.showProgress.nextEpisode!.number} ${show.showProgress.nextEpisode!.title}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),

                                          Text(show.watchedShow!.show.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      )
                                    : Container(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,

                      child: Center(
                        child: ArrowButton(visible: _isHovering && _canScrollLeft, icon: Icons.arrow_back_ios_new, onPressed: () => _scrollBy(-900)),
                      ),
                    ),

                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: ArrowButton(visible: _isHovering && _canScrollRight, icon: Icons.arrow_forward_ios, onPressed: () => _scrollBy(900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _updateArrows() {
    if (!_controller.hasClients) return;

    final pos = _controller.position;

    setState(() {
      _canScrollLeft = pos.pixels > 0;
      _canScrollRight = pos.pixels < pos.maxScrollExtent;
    });
  }

  void _scrollBy(double offset) {
    _controller.animateTo(_controller.offset + offset, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
