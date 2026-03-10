import 'dart:async';
import 'dart:ui';

import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/trakt_future.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/overview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ValueNotifier<String?> backgroundImage = ValueNotifier("https://image.tmdb.org/t/p/original/9n2tJBplPbgR2ca05hS5CKXwP2c.jpg");

  void _setBackground(String? image) {
    backgroundImage.value = image;
  }

  @override
  Widget build(BuildContext context) {
    var catalogWidget = FutureBuilder(
      future: Api.addonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final addons = snapshot.data!.where((e) => e.enabledResources.contains('catalog')).toList();

          return SizedBox.expand(
            child: Stack(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: backgroundImage,
                  builder: (context, image, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: image != null
                          ? ClipRect(
                              child: SizedBox(
                                key: ValueKey(image), // force AnimatedSwitcher to recognize new images
                                width: double.infinity,
                                height: 400, // only top portion
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12), // rounded corners at the bottom
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(Api.proxyImage(image), fit: BoxFit.cover),
                                      // Blur only the background
                                      BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 0.2, sigmaY: 0.2),
                                        child: Container(color: Colors.black.withValues(alpha: 0.65)),
                                      ),
                                      // Gradient overlay for readability
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [Colors.transparent, Colors.black],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(key: const ValueKey('empty'), height: 350, color: Colors.black),
                    );
                  },
                ),

                // Container(color: Colors.black.withOpacity(0.65)),
                Column(
                  children: [
                    Search(addons: addons),
                    Expanded(
                      child: ListView.builder(
                        itemCount: addons.length + 2,
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              if (TraktApi.accessToken.isNotEmpty) {
                                final future = TraktFuture.fetchHistory();
                                return TraktPage(itemsFuture: future, onItemHover: _setBackground);
                              } else {
                                return SizedBox();
                              }
                            case 1:
                              return SizedBox();
                            default:
                              {
                                final addon = addons[index - 2];
                                final catalogs = Api.generateCatalogs('https://cinemeta-catalogs.strem.io', 'top', addon.manifest!);
                                return loadCatalog(catalogs);
                              }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );

    return catalogWidget;
  }

  Widget loadCatalog(List<Catalog> catalogs) {
    return Column(
      children: catalogs.map((catalog) {
        final future = CatalogApi.fetchCatalogItems(catalog); // start immediately

        return CatalogPage(catalog: catalog, itemsFuture: future, onItemHover: _setBackground);
      }).toList(),
    );
  }
}

class Search extends StatefulWidget {
  const Search({super.key, required this.addons});
  final List<Addon> addons;

  @override
  State<Search> createState() => _SearchState();
}

enum SearchType { seriesAndMovies, series, movies, actors }

class _SearchState extends State<Search> {
  late SearchControllerModel searchModel;
  final ValueNotifier<SearchType> searchTypeNotifier = ValueNotifier(SearchType.seriesAndMovies);

  @override
  void initState() {
    super.initState();
    searchModel = SearchControllerModel();
  }

  @override
  Widget build(BuildContext context) {
    String label(SearchType type) {
      switch (type) {
        case SearchType.series:
          return "Shows";
        case SearchType.movies:
          return "Movies";
        case SearchType.seriesAndMovies:
          return "Shows & Movies";
        case SearchType.actors:
          return "Actors";
      }
    }

    return Padding(
      padding: EdgeInsets.all(8),
      child: SearchAnchor(
        isFullScreen: false,
        viewHintText: 'Search TV Shows, Movies & more...',
        viewLeading: ValueListenableBuilder<SearchType>(
          valueListenable: searchTypeNotifier,
          builder: (context, type, _) {
            return PopupMenuButton<SearchType>(
              icon: Row(children: [Icon(Icons.filter_list), SizedBox(width: 6), Text(label(type))]),
              onSelected: (t) => searchTypeNotifier.value = t,
              itemBuilder: (context) => SearchType.values.map((type) => PopupMenuItem<SearchType>(value: type, child: Text(label(type)))).toList(),
            );
          },
        ),
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            hintText: 'Search TV Shows, Movies & more...',
            onTap: () => controller.openView(),
            onChanged: (value) {
              controller.openView();
            },
          );
        },

        suggestionsBuilder: (context, controller) {
          searchModel.search(controller.text, widget.addons);
          return [
            ValueListenableBuilder<SearchType>(
              valueListenable: searchTypeNotifier,
              builder: (context, searchType, _) {
                return ListenableBuilder(
                  listenable: searchModel,
                  builder: (context, _) {
                    return Column(
                      children: searchModel.results
                          .where((item) {
                            switch (searchTypeNotifier.value) {
                              case SearchType.series:
                                return item.type == "series";

                              case SearchType.movies:
                                return item.type == "movie";

                              case SearchType.seriesAndMovies:
                                return item.type == "series" || item.type == "movie";

                              case SearchType.actors:
                                return item.type == "actor";
                            }
                          })
                          .map((item) {
                            return Container(
                              padding: EdgeInsets.all(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  final catalogItem = await StreamApi.fetchCatalogItem(item);
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => OverviewPage(item: catalogItem!)));
                                },
                                child: Tooltip(
                                  message: item.name,
                                  child: Row(
                                    children: [
                                      Ink(
                                        height: 100,
                                        width: 60,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(image: CachedNetworkImageProvider(item.poster), fit: BoxFit.cover),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),

                                      Container(width: 20),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        spacing: 8,
                                        children: [
                                          Text(item.name),
                                          Row(
                                            spacing: 8,
                                            children: [
                                              Chip(label: Text(item.type)),
                                              Chip(label: Text(item.releaseInfo)),
                                            ],
                                          ),
                                          Text(item.genres.join(', ')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                );
              },
            ),
          ];
        },
      ),
    );
  }
}

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;

  List<CatalogItem> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.length < 3) {
        results = [];
        notifyListeners();
        return;
      }

      loading = true;
      notifyListeners();

      try {
        results = await StreamApi.searchCatalogItems(query, addons);
      } finally {
        loading = false;
        notifyListeners();
      }
    });
  }
}

class CatalogPage extends StatefulWidget {
  final Catalog catalog;
  final Future<List<CatalogItem>> itemsFuture;
  final ValueChanged<String?> onItemHover;

  const CatalogPage({super.key, required this.catalog, required this.itemsFuture, required this.onItemHover});

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
          return Container(color: Colors.pink);
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data!;

        return Column(
          children: [
            Text('${widget.catalog.name} - ${widget.catalog.type[0].toUpperCase() + widget.catalog.type.substring(1)}'),
            CatalogRow(items: items, onItemHover: widget.onItemHover),
          ],
        );
      },
    );
  }
}

class TraktPage extends StatefulWidget {
  final Future<List<TraktShow>> itemsFuture;
  final ValueChanged<String?> onItemHover;

  const TraktPage({super.key, required this.itemsFuture, required this.onItemHover});

  @override
  State<TraktPage> createState() => _TraktPageState();
}

class _TraktPageState extends State<TraktPage> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TraktShow>>(
      future: widget.itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(color: Colors.pink);
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data!;

        return Column(
          children: [
            Text('Next Up'),
            TraktRow(items: items, onItemHover: widget.onItemHover),
          ],
        );
      },
    );
  }
}

class TraktRow extends StatefulWidget {
  final List<TraktShow> items;
  final ValueChanged<String?> onItemHover;

  const TraktRow({super.key, required this.items, required this.onItemHover});

  @override
  State<TraktRow> createState() => _TraktRowState();
}

class _TraktRowState extends State<TraktRow> {
  final ScrollController _controller = ScrollController();
  List<String?> _posterUrls = [];
  bool _isLoading = true;

  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _loadPosters();
    _controller.addListener(_updateArrows);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
    });
  }

  Future<void> _loadPosters() async {
    final urls = await Future.wait(widget.items.map((item) => TMDB.posterUrl(MediaType.show, item.tmdbId!.toString())));
    setState(() {
      _posterUrls = urls;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final poster = _posterUrls[index];

                if (poster == null) return const SizedBox(width: 128);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4), // space between posters
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Tooltip(
                              message: item.title,
                              child: GestureDetector(
                                onTap: () async {
                                  final catalogItem = await StreamApi.fetchCatalogItemById(item.imdbId!, "series");
                                  if (catalogItem == null) return;
                                  if (!context.mounted) return; // important after async gap
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => OverviewPage(item: catalogItem)));
                                },

                                child: NetworkPoster(
                                  poster: poster,
                                  onHover: () {
                                    widget.onItemHover(poster);
                                  },
                                  onExit: () {
                                    // optional: widget.onItemHover(null);
                                  },
                                ),
                                // child:
                              ),
                            ),
                          ),
                        ),
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

class CatalogRow extends StatefulWidget {
  final List<CatalogItem> items;
  final ValueChanged<String?> onItemHover;

  const CatalogRow({super.key, required this.items, required this.onItemHover});

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
        height: 200,
        child: Stack(
          children: [
            ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4), // space between posters
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Tooltip(
                              message: item.name,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => OverviewPage(item: item)));
                                },
                                child: NetworkPoster(
                                  poster: item.poster,
                                  onHover: () {
                                    widget.onItemHover(item.background);
                                  },
                                  onExit: () {
                                    // optional: widget.onItemHover(null);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
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
      progressIndicatorBuilder: (context, url, downloadProgress) => Center(child: CircularProgressIndicator(value: downloadProgress.progress)),
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
