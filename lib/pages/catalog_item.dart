import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
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
    // print("rerunningg");
    return FutureBuilder(
      future: ApiCache.getSearch("imdb", catalogItem.id, catalogItem.type),
      builder: (context, searchSnapshot) {
        switch (searchSnapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.done:
            {
              final Search search = searchSnapshot.data!;

              return FutureBuilder(
                future: ApiCache.getTmdbPoster(
                  catalogItem.type,
                  MediaType.user.fromTmdbSafe(catalogItem.type) == MediaType.show ? search.show!.ids.tmdb.toString() : search.movie!.ids.tmdb.toString(),
                ),
                builder: (context, tmdbPosterSnapshot) {
                  switch (tmdbPosterSnapshot.connectionState) {
                    case ConnectionState.active:
                    case ConnectionState.done:
                      {
                        return MouseRegion(
                          onEnter: (event) => setState(() {
                            _isHovering = true;
                          }),
                          onExit: (event) => setState(() {
                            _isHovering = false;
                          }),
                          child: GestureDetector(
                            onTap: () async {
                              final show = catalogItem.type == "series";
                              final item = show
                                  ? await TraktApi.fetchShowWithProgress(searchSnapshot.data!.show!.ids.trakt)
                                  : await TraktApi.fetchMovie(searchSnapshot.data!.movie!.ids.trakt.toString());
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => show
                                      ? EpisodeOverview(item: item! as TraktWatchedShowWithProgress, selectedEpisode: null)
                                      : MovieOverview(item: item! as Movie),
                                ),
                              );
                            },

                            child: Container(
                              color: Colors.transparent,
                              width: 200,
                              child: Padding(
                                padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _isHovering ? Colors.white : Colors.transparent),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadiusGeometry.circular(8),
                                    child: AnimatedScale(
                                      scale: _isHovering ? 1.1 : 1,
                                      duration: const Duration(milliseconds: 300),
                                      child: Image.memory(tmdbPosterSnapshot.data!, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    case _:
                      return const SizedBox();
                  }
                },
              );
            }
          case _:
            return SizedBox();
        }
      },
    );
  }
}
