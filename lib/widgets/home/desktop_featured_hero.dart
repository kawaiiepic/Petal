import 'package:petal/widgets/home/featured_position.dart';
import 'dart:math' as math;

import 'package:petal/api/api.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/arrow_button.dart';
import 'package:petal/widgets/home/featured_autoplay.dart';
import 'package:petal/widgets/home/featured_details_button.dart';
import 'package:petal/widgets/home/featured_pagination.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Featured artwork flush with the edges of the desktop content area.
class DesktopFeaturedHero extends StatefulWidget {
  const DesktopFeaturedHero({super.key, required this.items, this.loading = false});

  final List<CatalogItem> items;
  final bool loading;

  @override
  State<DesktopFeaturedHero> createState() => _DesktopFeaturedHeroState();
}

class _DesktopFeaturedHeroState extends State<DesktopFeaturedHero> {
  late int _index = FeaturedPosition.restore(widget.items);

  @override
  void didUpdateWidget(covariant DesktopFeaturedHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items && widget.items.isNotEmpty) {
      _index = FeaturedPosition.restore(widget.items);
    }
  }

  void _select(int index) {
    if (index < 0 || index >= widget.items.length) return;
    FeaturedPosition.remember(widget.items[index]);
    setState(() => _index = index);
  }

  void _move(int delta) => _select((_index + delta) % widget.items.length);

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return SizedBox(
        height: math.max(320.0, MediaQuery.sizeOf(context).height * .55),
        width: double.infinity,
        child: const MediaArtwork(isLoading: true),
      );
    }
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return FeaturedAutoplay(
      enabled: widget.items.length > 1,
      onAdvance: () => _move(1),
      child: _banner(context),
    );
  }

  Widget _banner(BuildContext context) {
    final item = widget.items[_index];
    final hasMultiple = widget.items.length > 1;
    final info = [
      item.type == 'movie' ? 'Movie' : 'Series',
      if (item.year > 0) '${item.year}',
      ...item.genres.take(2),
    ].join('  ·  ');
    final hasBackdrop = item.background.isNotEmpty;
    final url = hasBackdrop ? item.background : item.poster;
    final artwork = Uri.tryParse(url)?.host == Uri.parse(Api.ServerUrl).host
        ? url
        : Api.proxyImage(url);

    final height = math.max(320.0, MediaQuery.sizeOf(context).height * .55);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Color(0xFF17181A)),
              Positioned.fill(
                left: hasBackdrop ? 0 : width * .45,
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 330),
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  child: MediaArtwork(key: ValueKey(url), imageUrl: artwork),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xDD080809),
                      Color(0x54080809),
                      Color(0x00080809),
                    ],
                    stops: [0, .52, 1],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF5080809), Color(0x00080809)],
                    stops: [0, .85],
                  ),
                ),
              ),
              Positioned(
                left: hasMultiple ? 68 : 32,
                right: hasMultiple ? 68 : 32,
                bottom: hasMultiple ? 49 : 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Color(0xFFD3D5DA),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (width * .061).clamp(38.0, 76.0),
                        fontWeight: FontWeight.w800,
                        height: 1.04,
                        letterSpacing: -.9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDCDEE2),
                        fontSize: 13,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: width * .66),
                        child: Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFEBECEE),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FeaturedDetailsButton(item: item),
                  ],
                ),
              ),
              if (hasMultiple) ...[
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _arrow(
                      -1,
                      'Previous featured title',
                      LucideIcons.arrowBigLeft,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _arrow(
                      1,
                      'Next featured title',
                      LucideIcons.arrowBigRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FeaturedPagination(
                      count: widget.items.length,
                      selectedIndex: _index,
                      onSelected: _select,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _arrow(int delta, String label, IconData icon) => ArrowButton(
    visible: true,
    icon: icon,
    semanticLabel: label,
    onPressed: () => _move(delta),
  );
}
