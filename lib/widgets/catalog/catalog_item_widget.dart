import 'package:flutter/services.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

class CatalogItemWidget extends StatefulWidget {
  final CatalogItem? catalogItem;

  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  State<StatefulWidget> createState() => _CatalogItemWidget();
}

class _CatalogItemWidget extends State<CatalogItemWidget> {
  CatalogItem? catalogItem;

  @override
  void initState() {
    super.initState();
    catalogItem = widget.catalogItem;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsGeometry.fromLTRB(2.w, 8, 2.w, 8),
    child: HoverableItem(
      image: catalogItem != null
          ? CachedNetworkImage(
              imageUrl: catalogItem!.poster,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.pink.withAlpha(1)).asSkeleton(leaf: true),
              errorWidget: (context, url, error) => Container(
                color: Colors.white.withAlpha(30),
                child: Column(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_rounded, size: 50),
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
          leading: const Icon(Icons.play_arrow_rounded),
          trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.enter)),
          onPressed: (_) {},
          child: const Text('Play'),
        ),
        MenuButton(
          leading: const Icon(Icons.dns_outlined),
          trailing: const MenuShortcut(activator: SingleActivator(LogicalKeyboardKey.bracketLeft, control: true)),
          onPressed: (_) {},
          child: const Text('Select Source'),
        ),
        const MenuDivider(),
        MenuButton(leading: const Icon(Icons.info_outline_rounded), onPressed: (_) {}, child: const Text('More Info')),
        const MenuDivider(),
        MenuButton(
          leading: const Icon(Icons.bookmark_outline_rounded),
          onPressed: (_) {
            // toggle watchlist state for item.id
          },
          child: Text(true ? 'Remove from Watchlist' : 'Add to Watchlist'),
        ),
        MenuButton(
          leading: const Icon(Icons.thumb_up_outlined),
          onPressed: (_) {
            // like/rate item.id
          },
          child: const Text('Rate'),
        ),
      ],
    ),
  );
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
    return MouseRegion(
      onEnter: (event) => setState(() {
        _isHovering = true;
      }),
      onExit: (event) => setState(() {
        _isHovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,

        child: ContextMenu(
          enabled: widget.contextItems != null,
          items: widget.contextItems ?? [],
          child: Container(
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
          ),
        ),
      ),
    );
  }
}
