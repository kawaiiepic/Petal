import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/user_library.dart';
import 'package:petal/models/trakt/enum/media_type.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class CatalogItemWidget extends StatefulWidget {
  final CatalogItem? catalogItem;

  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  State<StatefulWidget> createState() => _CatalogItemWidget();
}

class _CatalogItemWidget extends State<CatalogItemWidget> with AutomaticKeepAliveClientMixin {
  CatalogItem? catalogItem;
  late final String _posterUrl;

  @override
  bool get wantKeepAlive => catalogItem != null;

  @override
  void initState() {
    super.initState();
    catalogItem = widget.catalogItem;
    final poster = catalogItem?.poster ?? '';
    _posterUrl = poster.isEmpty || poster.contains('blossomvale.dev') ? poster : Api.proxyImage(poster);
    if (_posterUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        precacheImage(CachedNetworkImageProvider(_posterUrl), context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(2.w, 8, 2.w, 8),
      child: HoverableItem(
        image: catalogItem != null
            ? CachedNetworkImage(
                imageUrl: _posterUrl,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                fadeInDuration: Duration.zero,
                placeholder: (context, url) => Container(color: Colors.white.withAlpha(20)).asSkeleton(leaf: true),
                errorWidget: (context, url, error) => Container(
                  color: Colors.white.withAlpha(30),
                  child: Column(
                    spacing: 8,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.tv, size: 50),
                      Text(catalogItem!.name, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : Avatar(initials: '', borderRadius: 12).asSkeleton(),
        onTap: () {
          if (catalogItem != null) context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
        },
        contextItems: [
          MenuButton(
            leading: const Icon(LucideIcons.play),
            trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.enter)),
            onPressed: (_) {
              if (catalogItem != null) context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
            },
            child: const Text('Play'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.server),
            trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
            onPressed: (_) {
              if (catalogItem != null) context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
            },
            child: const Text('Select Source'),
          ),
          const MenuDivider(),
          MenuButton(
            leading: const Icon(LucideIcons.info),
            onPressed: (_) {
              if (catalogItem != null) context.push('/${catalogItem!.type}?imdb=${catalogItem!.id}');
            },
            child: const Text('More Info'),
          ),
          const MenuDivider(),
          MenuButton(
            leading: const Icon(LucideIcons.bookmark),
            onPressed: (_) async {
              if (catalogItem == null) return;
              final resolved = await _resolveLibraryTarget(catalogItem!);
              if (resolved == null) return;
              await UserLibrary.toggleWatchlist(resolved.$1, resolved.$2, name: catalogItem!.name);
            },
            child: const Text('Watchlist'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.check),
            onPressed: (_) async {
              if (catalogItem == null) return;
              final resolved = await _resolveLibraryTarget(catalogItem!);
              if (resolved == null) return;
              await UserLibrary.toggleWatched(resolved.$1, resolved.$2);
            },
            child: const Text('Watched'),
          ),
          MenuButton(
            leading: const Icon(LucideIcons.thumbsUp),
            onPressed: (_) async {
              if (catalogItem == null) return;
              final resolved = await _resolveLibraryTarget(catalogItem!);
              if (resolved == null) return;
              await UserLibrary.cycleRating(resolved.$1, resolved.$2);
            },
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }
}

Future<(int, MediaType)?> _resolveLibraryTarget(CatalogItem item) async {
  final type = item.type == 'movie' ? MediaType.movie : MediaType.show;
  final parsed = int.tryParse(item.id);
  if (parsed != null && !item.id.startsWith('tt')) return (parsed, type);
  try {
    final result = await ApiCache.getTmdbSearch(item.id);
    final match = type == MediaType.movie ? result.movies.firstOrNull : result.tv.firstOrNull;
    if (match == null) return null;
    return (match.id, type);
  } catch (_) {
    return null;
  }
}

class HoverableItem extends StatefulWidget {
  final Widget? image;
  final Widget? extraWidget;
  final VoidCallback? onTap;
  final List<MenuItem>? contextItems;
  final Orientation orientation;

  const HoverableItem({super.key, required this.image, this.onTap, this.contextItems, this.orientation = Orientation.portrait, this.extraWidget});

  @override
  State<StatefulWidget> createState() => _HoverableItem();
}

class _HoverableItem extends State<HoverableItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: widget.orientation == Orientation.portrait ? 3 / 4 : 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _isHovering ? Colors.white : Colors.transparent),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(12.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(scale: _isHovering ? 1.1 : 1, duration: const Duration(milliseconds: 300), child: widget.image),
                if (widget.extraWidget != null) widget.extraWidget!,
              ],
            ),
          ),
        ),
      ),
    );

    final tappable = MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: card,
      ),
    );

    if (widget.contextItems == null || widget.contextItems!.isEmpty) return tappable;

    return ContextMenu(
      enabled: true,
      items: widget.contextItems!,
      child: tappable,
    );
  }
}
