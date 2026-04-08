import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/tmdb/tmdb_models.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class CatalogItemWidget extends StatefulWidget {
  final CatalogItem catalogItem;

  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  State<StatefulWidget> createState() => _CatalogItemWidget();
}

class _CatalogItemWidget extends State<CatalogItemWidget> {
  late final CatalogItem catalogItem;
  late final Future<TmdbSearchResult> _searchFuture;

  @override
  void initState() {
    super.initState();
    catalogItem = widget.catalogItem;
    _searchFuture = ApiCache.getTmdbSearch(catalogItem.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _searchFuture,
    builder: (context, searchSnapshot) => HoverableItem(
      image: searchSnapshot.hasData
          ? CachedNetworkImage(
              imageUrl: searchSnapshot.hasData ? (catalogItem.type == "series" ? searchSnapshot.data!.tv[0] : searchSnapshot.data!.movies[0]).posterPath : '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            )
          : Container(width: 1, height: 1, color: Colors.pink),
      onTap: () {
        if (searchSnapshot.hasData) {
          print(catalogItem.type);
          final tmdbItem = catalogItem.type == "series" ? searchSnapshot.data!.tv[0] : searchSnapshot.data!.movies[0];
          context.push('/catalogs/${catalogItem.type}/${tmdbItem.id}');
        }
      },
    ).asSkeleton(snapshot: searchSnapshot),
  );
}

class HoverableItem extends StatefulWidget {
  final Widget image;
  final VoidCallback? onTap;

  const HoverableItem({super.key, required this.image, this.onTap});

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

        child: Container(
          color: Colors.transparent,
          width: 200,
          height: 300,
          child: Padding(
            padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: _isHovering ? Colors.white : Colors.transparent),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(8),
                child: AnimatedScale(scale: _isHovering ? 1.1 : 1, duration: const Duration(milliseconds: 300), child: widget.image),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
