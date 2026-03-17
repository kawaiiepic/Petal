import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/pages/dashboard/dashboard.dart';
import 'package:blssmpetal/pages/episode_overview.dart';
import 'package:blssmpetal/pages/overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

typedef ItemHoverCallback = void Function(CatalogItem? item, String? background);

class NextUpRow extends StatefulWidget {
  final ValueNotifier<CatalogItem?> selectedItem;
  final ItemHoverCallback onItemHover;

  const NextUpRow({super.key, required this.selectedItem, required this.onItemHover});

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

  @override
  void initState() {
    super.initState();
    // _loadPosters();
    // _controller.addListener(_updateArrows);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // _updateArrows();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: TraktApi.fetchWatchedShowWithProgress(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final itemCount = snapshot.hasData ? data.length : 10;

        final radius = BorderRadius.circular(8);

        final loadingInk = Ink(
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withValues(alpha: 0.3)),
                                  );
        return SizedBox(
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            controller: _controller,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final isLoading = !snapshot.hasData;
              final show = !isLoading ? snapshot.data![index] : null;
              return MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 2 / 3,
                          child: isLoading
                              ? InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {},
                                  child: loadingInk,
                                )
                              : Tooltip(
                                  message: show!.watchedShow.show.title,
                                  child: InkWell(
                                    onTap: () {

                                      Navigator.push(context, MaterialPageRoute(builder: (_) => EpisodeOverview(item: show, selectedEpisode: null,)));
                                    },
                                    child: FutureBuilder(
                                      future: TMDB.poster(MediaType.show, show.watchedShow.show.ids.tmdb!.toString()),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return loadingInk;
                                        return Ink(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(image: Image.memory(snapshot.data!).image, fit: BoxFit.cover),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                        ),

                        !isLoading
                            ? Column(
                                children: [
                                  Text(
                                    "${show!.showProgress.nextEpisode!.season}x${show.showProgress.nextEpisode!.number} ${show.showProgress.nextEpisode!.title}",
                                  ),

                                  Text(show.watchedShow.show.title),
                                ],
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
