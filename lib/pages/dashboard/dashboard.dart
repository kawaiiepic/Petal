import 'dart:async';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/router/routes/catalog_widget.dart';
import 'package:blssmpetal/pages/dashboard/search_widget.dart';
import 'package:blssmpetal/pages/trakt_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Text('Boop');
    return CustomScrollView(
      slivers: [
        // Search(),
        SliverAppBar(
          pinned: true,
          floating: true,
          primary: false,
          expandedHeight: 100.0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          forceMaterialTransparency: false,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: const Center(child: Search()),
        ),
        NextUpRow(),
        CatalogWidget(),
      ],
    );
  }

  // Widget loadCatalog(List<Catalog> catalogs) {
  //   return Column(
  //     spacing: 20,
  //     children: catalogs.map((catalog) {
  //       final future = CatalogApi.fetchCatalogItems(catalog);

  //       return CatalogPage(catalog: catalog, itemsFuture: future);
  //     }).toList(),
  //   );
  // }
}

class CatalogPage extends StatefulWidget {
  final Catalog catalog;
  final Future<List<CatalogItem>> itemsFuture;

  const CatalogPage({super.key, required this.catalog, required this.itemsFuture});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CatalogItem>>(
      future: widget.itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data!;

        return Column(
          spacing: 8,
          children: [
            Text('${widget.catalog.name} - ${widget.catalog.type[0].toUpperCase() + widget.catalog.type.substring(1)}'),
            CatalogRow(items: items),
          ],
        );
      },
    );
  }
}

class CatalogRow extends StatefulWidget {
  final List<CatalogItem> items;

  const CatalogRow({super.key, required this.items});

  @override
  State<CatalogRow> createState() => _CatalogRowState();
}

class _CatalogRowState extends State<CatalogRow> {
  final ScrollController _controller = ScrollController();

  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateArrows);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final loadingInk = SizedBox(
                  width: 120,
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.3), // fixed: use withOpacity, not withValues
                      ),
                    ),
                  ),
                );

                return FutureBuilder(
                  future: TraktApi.search("imdb", item.id, item.type),
                  builder: (context, searchSnapshot) {
                    if (!searchSnapshot.hasData) {
                      return loadingInk;
                    }
                    if (searchSnapshot.hasError) {
                      return loadingInk;
                    } else {

                      final search = searchSnapshot.data!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4), // space between posters
                        child: SizedBox(
                          width: 120,
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 2 / 3,
                                child: Tooltip(
                                  message: item.name,
                                  child: InkWell(
                                    // onTap: () async {
                                    //   if (item.type == "series") {
                                    //     if (mounted) {
                                    //       final show = await TraktApi.fetchShowWithProgress(searchSnapshot.data!.show!.ids.trakt);
                                    //       showDialog(
                                    //         context: context,
                                    //         builder: (context) {
                                    //           return Dialog(
                                    //             insetPadding: const EdgeInsets.all(16), // padding from screen edges
                                    //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    //             child: ClipRRect(
                                    //               borderRadius: BorderRadiusGeometry.circular(8),
                                    //               child: EpisodeOverview(media: search.,),
                                    //             ),
                                    //           );
                                    //         },
                                    //       );
                                    //     }
                                    //     // Navigator.push(context, MaterialPageRoute(builder: (_) => EpisodeOverview(item: show!, selectedEpisode: null)));
                                    //   } else {
                                    //     if (mounted) {
                                    //       final movie = await TraktApi.fetchMovie(searchSnapshot.data!.movie!.ids.trakt.toString());
                                    //       showDialog(
                                    //         context: context,
                                    //         builder: (context) {
                                    //           return Dialog(
                                    //             insetPadding: const EdgeInsets.all(16), // padding from screen edges
                                    //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    //             child: ClipRRect(
                                    //               borderRadius: BorderRadiusGeometry.circular(8),
                                    //               child: MovieOverview(item: movie),
                                    //             ),
                                    //           );
                                    //         },
                                    //       );
                                    //     }
                                    //   }
                                    // },
                                    child: FutureBuilder(
                                      future: TMDB.poster(
                                        item.type == "series" ? MediaType.show : MediaType.movie,
                                        item.type == "series"
                                            ? searchSnapshot.data!.show!.ids.tmdb.toString()
                                            : searchSnapshot.data!.movie!.ids.tmdb.toString(),
                                      ),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return loadingInk;
                                        if (snapshot.hasError) {
                                          return Text('Error');
                                        }
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
                            ],
                          ),
                        ),
                      );
                    }
                  },
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

class NetworkPoster extends StatefulWidget {
  final String poster;
  final VoidCallback? onHover;
  final VoidCallback? onExit;
  const NetworkPoster({super.key, required this.poster, this.onHover, this.onExit});

  @override
  State<NetworkPoster> createState() => _NetworkPosterState();
}

class _NetworkPosterState extends State<NetworkPoster> {
  late CachedNetworkImage _image;

  @override
  void initState() {
    super.initState();
    _image = CachedNetworkImage(
      imageUrl: widget.poster,
      progressIndicatorBuilder: (context, url, downloadProgress) => Container(color: Colors.black.withOpacity(0.05)),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(onEnter: (_) => widget.onHover?.call(), onExit: (_) => widget.onExit?.call(), child: _image);
  }
}

class ArrowButton extends StatefulWidget {
  final bool visible;
  final IconData icon;
  final VoidCallback onPressed;

  const ArrowButton({super.key, required this.visible, required this.icon, required this.onPressed});

  @override
  State<ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: _hovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_hovered ? 0.65 : 0.45),
                shape: BoxShape.circle,
                boxShadow: [if (_hovered) const BoxShadow(blurRadius: 8, color: Colors.black26)],
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox(width: 36, height: 36, child: Icon(widget.icon, size: 18, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
