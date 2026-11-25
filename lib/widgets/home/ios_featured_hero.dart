import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/navigation/ios_navigation_dock.dart';
import 'package:petal/navigation/user_profile.dart';
import 'package:petal/widgets/home/featured_autoplay.dart';
import 'package:petal/widgets/home/featured_details_button.dart';
import 'package:petal/widgets/home/featured_pagination.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Edge-to-edge featured artwork with a manually paged carousel.
class IosFeaturedHero extends StatefulWidget {
  const IosFeaturedHero({super.key, required this.items, this.loading = false});

  final List<CatalogItem> items;
  final bool loading;

  @override
  State<IosFeaturedHero> createState() => _IosFeaturedHeroState();
}

class _IosFeaturedHeroState extends State<IosFeaturedHero> {
  final _pages = PageController(keepPage: false);
  int _index = 0;

  @override
  void didUpdateWidget(covariant IosFeaturedHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _index = 0;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _advance() {
    if (!_pages.hasClients) return;
    if (_index + 1 >= widget.items.length) {
      _pages.jumpToPage(0);
    } else {
      _goTo(_index + 1);
    }
  }

  void _goTo(int index) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FeaturedAutoplay(
    enabled: widget.items.length > 1,
    onAdvance: _advance,
    child: _banner(context),
  );

  Widget _banner(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = widget.items;
    final hasArt = items.isNotEmpty;

    final viewportHeight = MediaQuery.sizeOf(context).height;
    final height = (viewportHeight * .60).clamp(350.0, 1000.0);
    // Keep controls above the dock on unusually short viewports.
    final dockTop =
        viewportHeight -
        IosNavigationDock.clearance -
        MediaQuery.viewPaddingOf(context).bottom;
    final controlsInset = (height - dockTop).clamp(0.0, 100.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hasArt || colors.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: hasArt || widget.loading ? height : null,
        child: Stack(
          children: [
            if (widget.loading)
              const Positioned.fill(child: MediaArtwork(isLoading: true)),
            if (hasArt && !widget.loading)
              Positioned.fill(
                child: PageView.builder(
                  key: ValueKey(items),
                  controller: _pages,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _slide(
                    context,
                    items[index],
                    colors.background,
                    controlsInset,
                  ),
                ),
              ),
            Align(
              key: const ValueKey('home-heading'),
              alignment: Alignment.topCenter,
              heightFactor: 1,
              child: _header(hasArt ? Colors.white : colors.foreground),
            ),
            if (items.length > 1)
              Positioned(
                bottom: 8 + controlsInset,
                left: 0,
                right: 0,
                child: Center(
                  child: FeaturedPagination(
                    count: items.length,
                    selectedIndex: _index,
                    onSelected: _goTo,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(Color color) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 14, 8),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text(
              'Home',
              style: TextStyle(
                color: color,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -.9,
              ),
            ),
          ),
          const UserProfile(avatarOnly: true),
        ],
      ),
    ),
  );

  Widget _slide(
    BuildContext context,
    CatalogItem item,
    Color background,
    double controlsInset,
  ) {
    final portrait = MediaQuery.sizeOf(context).width < 600;
    final path = portrait && item.poster.isNotEmpty || item.background.isEmpty
        ? item.poster
        : item.background;
    final metadata = [
      item.type == 'movie' ? 'Movie' : 'TV Show',
      ...item.genres.take(2),
      if (item.genres.isEmpty && item.year > 0) '${item.year}',
    ].join(' · ');
    final title = Text(
      item.name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 38,
        fontWeight: FontWeight.w900,
        height: 1.02,
        letterSpacing: -1,
      ),
    );
    final hasLogo =
        item.logo.isNotEmpty &&
        Uri.tryParse(item.logo)?.path.toLowerCase().endsWith('.svg') == false;
    return Stack(
      fit: StackFit.expand,
      children: [
        MediaArtwork(
          imageUrl: Api.proxyImage(path),
          alignment: Alignment.topCenter,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x99000000),
                const Color(0x00000000),
                const Color(0xD9090A0C),
                background,
              ],
              stops: const [0, .32, .88, 1],
            ),
          ),
        ),
        Positioned(
          bottom: (widget.items.length > 1 ? 58 : 24) + controlsInset,
          left: 22,
          right: 22,
          child: Column(
            children: [
              if (hasLogo)
                Semantics(
                  image: true,
                  label: item.name,
                  excludeSemantics: true,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 92,
                      maxWidth: 320,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: Api.proxyImage(item.logo),
                      fit: BoxFit.contain,
                      placeholder: (_, _) => title,
                      errorWidget: (_, _, _) => title,
                    ),
                  ),
                )
              else
                title,
              const SizedBox(height: 12),
              Text(
                metadata,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FeaturedDetailsButton(item: item),
            ],
          ),
        ),
      ],
    );
  }
}
