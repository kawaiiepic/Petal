import 'dart:async';
import 'dart:ui';

import 'package:blssmpetal/api/api.dart';
import 'package:blssmpetal/api/catalog_helper.dart';
import 'package:blssmpetal/models/catalog.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/dashboard/search_widget.dart';
import 'package:blssmpetal/pages/dashboard/trakt_widget.dart';
import 'package:blssmpetal/pages/overview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final ValueNotifier<String?> backgroundImage = ValueNotifier(null);

  final ValueNotifier<CatalogItem?> selectedItem = ValueNotifier(null);

  void setSelectedItem(CatalogItem? item, String? poster) {
    selectedItem.value = item;
    backgroundImage.value = poster;
  }

  void _setBackground(String? image) {
    backgroundImage.value = image;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: Api.addonsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Search(addons: snapshot.data!);
            }
            return Container();
          },
        ),
        NextUpRow(selectedItem: selectedItem, onItemHover: setSelectedItem),

        FutureBuilder(
          future: Api.addonsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final addon = snapshot.data![index];
                    final catalogs = Api.generateCatalogs('https://cinemeta-catalogs.strem.io', 'top', addon.manifest!);
                    return loadCatalog(catalogs);
                  },
                ),
              );
            }
            return Container();
          },
        ),
      ],
    );

    return FutureBuilder(
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
                          : Container(height: 350, color: Colors.black),
                    );
                  },
                ),

                // Container(color: Colors.black.withOpacity(0.65)),
                Expanded(
                  child: Column(
                    children: [
                      Search(addons: addons),

                      // NextUpRow(selectedItem: selectedItem, onItemHover: setSelectedItem),
                      // Expanded(
                      //   child: ListView.builder(
                      //     itemCount: addons.length + 2,
                      //     itemBuilder: (context, index) {
                      //       switch (index) {
                      //         case 0:
                      //           if (TraktApi.accessToken.isNotEmpty) {
                      //             final future = TraktFuture.fetchHistory();
                      //             return TraktPage(selectedItem: selectedItem, itemsFuture: future, onItemHover: setSelectedItem);
                      //           } else {
                      //             return SizedBox();
                      //           }
                      //         case 1:
                      //           return SizedBox();
                      //         default:
                      //           {
                      //             final addon = addons[index - 2];
                      //             final catalogs = Api.generateCatalogs('https://cinemeta-catalogs.strem.io', 'top', addon.manifest!);
                      //             return loadCatalog(catalogs);
                      //           }
                      //       }
                      //     },
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
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
          return Text("Waiting");
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
