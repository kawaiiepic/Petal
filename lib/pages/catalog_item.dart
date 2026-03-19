import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/tmdb/tmdb.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/models/trakt/enum/media_type.dart';
import 'package:blssmpetal/pages/episode_overview.dart';
import 'package:blssmpetal/pages/movie_overview.dart';
import 'package:flutter/material.dart';

class CatalogItemWidget extends StatefulWidget {
  final CatalogItem catalogItem;

  const CatalogItemWidget({super.key, required this.catalogItem});

  @override
  State<StatefulWidget> createState() => _CatalogItemWidget();
}

class _CatalogItemWidget extends State<CatalogItemWidget> {
  late final CatalogItem catalogItem;

  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    catalogItem = widget.catalogItem;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      // child: SizedBox(height: 10, child: Text(_isHovering ? "Hovering" :catalogItem.name)),
      child: FutureBuilder(
        future: ApiCache.getSearch("imdb", catalogItem.id, catalogItem.type),
        builder: (context, searchSnapshot) {
          switch (searchSnapshot.connectionState) {
            case ConnectionState.active:
            case ConnectionState.done:
              {
                final Search search = searchSnapshot.data!;

                return Text('Gay');
                // FutureBuilder()
              }
            case _:
              return SizedBox();
          }
        },
      ),
    );
  }
}
