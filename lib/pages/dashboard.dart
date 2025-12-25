import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/api/trakt/traktauth.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/streams.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ValueNotifier<String?> backgroundImage = ValueNotifier(null);

  void _setBackground(String? image) {
    backgroundImage.value = image;
  }

  @override
  Widget build(BuildContext context) {
    // fetchHistory();

    return FutureBuilder(
      future: Api.addonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final addons = snapshot.data!.where((e) => e.enabledResources.contains('catalog')).toList();

          return Stack(
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: backgroundImage,
                builder: (context, image, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: image == null
                        ? Container(color: Colors.black)
                        : Container(
                            key: ValueKey(image),
                            decoration: BoxDecoration(
                              image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                            ),
                          ),
                  );
                },
              ),

              Container(color: Colors.black.withOpacity(0.65)),

              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: addons.length,
                      itemBuilder: (context, index) {
                        final addon = addons[index];
                        final catalogs = Api.generateCatalogs('https://cinemeta-catalogs.strem.io', 'top', addon.manifest!);
                        return loadCatalog(catalogs);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  void fetchHistory() async {
    final trakt = TraktApi(clientId: TraktAuth.clientId, accessToken: TraktAuth.accessToken);
    final nextUp = await trakt.getNextUp(limit: 10);

    Future<TraktNextUpItem?> buildNextUp(TraktShow show, {limit = 50}) async {
      if (show.traktId == null) return null;

      int index = 0;

      final progress = await trakt.fetchShowProgress(show.traktId!);

      final next = progress.nextEpisode;
      if (next == null) return null;
      return TraktNextUpItem(show: show, season: next['season'], episode: next['number'], title: next['title'], progress: progress.completed);
    }

    for (var item in nextUp) {
      var nextUpComplete = await buildNextUp(item.show);
      if (nextUpComplete != null) {
        print(nextUpComplete.show.title);
      }
    }
  }

  Widget loadCatalog(List<Catalog> catalogs) {
    return Column(
      children: catalogs.asMap().entries.map((entry) {
        if (entry.key > 0) return SizedBox();
        return CatalogPage(catalog: entry.value, onItemHover: _setBackground);
      }).toList(),
    );
  }
}

class CatalogPage extends StatefulWidget {
  final Catalog catalog;
  final ValueChanged<String?> onItemHover;

  const CatalogPage({super.key, required this.catalog, required this.onItemHover});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late Future<List<CatalogItem>> _itemsFuture;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _itemsFuture = CatalogApi.fetchCatalogItems(widget.catalog);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CatalogItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
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
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => StreamsPage(item: item)));
                                },
                                child: NetworkPoster(
                                  poster: item.poster,
                                  onHover: () {
                                    widget.onItemHover(item.background ?? item.poster);
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
  bool _loaded = false;
  late Image _image;

  @override
  void initState() {
    super.initState();
    _image = Image.network(widget.poster, fit: BoxFit.cover);

    final ImageStream stream = _image.image.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (info, _) {
          if (mounted) {
            setState(() {
              _loaded = true;
            });
          }
        },
        onError: (error, stackTrace) {
          if (mounted) {
            setState(() {
              _loaded = true; // stop loading spinner on error
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover?.call(),
      onExit: (_) => widget.onExit?.call(),
      child: Stack(
        children: [
          _image,
          if (!_loaded) const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
    );
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
