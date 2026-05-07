import 'dart:async';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/api/tmdb/tmdb_models.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' as material;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum SearchType { seriesAndMovies, series, movies, actors }

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;
  String _currentQuery = "";

  List<SearchResult> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    if (_currentQuery.trim() == query.trim()) return;
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _currentQuery = query;
      if (query.isEmpty) {
        results = [];

        notifyListeners();
        return;
      }

      loading = true;
      notifyListeners();

      try {
        final raw = (await StreamApi.searchCatalogItems(query, addons)).take(5);
        final enriched = await Future.wait(
          raw.map((item) async {
            final search = await ApiCache.getTmdbSearch(item.id);
            final tmdbResults = item.type == "series" ? search.tv : search.movies;
            if (tmdbResults.isEmpty) return null;
            return SearchResult(
              id: item.id,
              name: item.name,
              type: item.type,
              slug: item.slug,
              poster: item.poster,
              background: item.background,
              logo: item.logo,
              description: item.description,
              year: item.year,
              runtime: item.runtime,
              imdbRating: item.imdbRating,
              awards: item.awards,
              country: item.country,
              releaseInfo: item.releaseInfo,
              genres: item.genres,
              cast: item.cast,
              directors: item.directors,
              writers: item.writers,
              trailers: item.trailers,
              seasons: item.seasons,
              tmdbMedia: tmdbResults.first,
            );
          }),
        );
        results = enriched.whereType<SearchResult>().toList();
      } finally {
        loading = false;
        notifyListeners();
      }
    });
  }
}

class SearchResult extends CatalogItem {
  final TmdbMedia tmdbMedia;
  SearchResult({
    required super.id,
    required super.name,
    required super.type,
    required super.slug,
    required super.poster,
    required super.background,
    required super.logo,
    required super.description,
    required super.year,
    required super.runtime,
    required super.imdbRating,
    required super.awards,
    required super.country,
    required super.releaseInfo,
    required super.genres,
    required super.cast,
    required super.directors,
    required super.writers,
    required super.trailers,
    required super.seasons,
    required this.tmdbMedia,
  });
}

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  late SearchControllerModel searchModel;
  final ValueNotifier<SearchType> searchTypeNotifier = ValueNotifier(SearchType.seriesAndMovies);

  @override
  void initState() {
    super.initState();
    searchModel = SearchControllerModel();
  }

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

  @override
  Widget build(BuildContext context) {
    Widget? cacheWidget;
    return Padding(
      padding: EdgeInsets.all(8),
      child: material.SearchAnchor(
        isFullScreen: false,
        viewHintText: 'Search TV Shows, Movies & more...',
        viewLeading: ValueListenableBuilder<SearchType>(
          valueListenable: searchTypeNotifier,
          builder: (context, type, _) {
            return material.PopupMenuButton<SearchType>(
              icon: Row(children: [Icon(Icons.filter_list), SizedBox(width: 6), Text(label(type))]),
              onSelected: (t) => searchTypeNotifier.value = t,
              itemBuilder: (context) => SearchType.values.map((type) => material.PopupMenuItem<SearchType>(value: type, child: Text(label(type)))).toList(),
            );
          },
        ),
        builder: (context, controller) {
          return material.SearchBar(
            controller: controller,
            hintText: 'Search TV Shows, Movies & more...',
            onTap: () => controller.openView(),
            onChanged: (value) {
              controller.openView();
            },
          );
        },

        suggestionsBuilder: (context, controller) {
          return [
            FutureBuilder(
              future: ApiCache.getAddons(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox();
                }

                searchModel.search(controller.text, snapshot.data!);

                if (cacheWidget != null && searchModel._debounce != null && searchModel._debounce!.isActive) return cacheWidget!;

                cacheWidget = ValueListenableBuilder<SearchType>(
                  valueListenable: searchTypeNotifier,
                  builder: (context, searchType, _) {
                    return ListenableBuilder(
                      listenable: searchModel,
                      builder: (context, _) {
                        return Column(
                          children:
                              extractTop(
                                query: searchModel._currentQuery,
                                choices: searchModel.results.where((item) {
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
                                }).toList(),
                                limit: 10,
                                cutoff: 80,
                                getter: (x) => x.name,
                              ).map((item) {
                                final choice = item.choice;
                                return Padding(
                                  padding: EdgeInsetsGeometry.all(2),
                                  child: Button(
                                    // borderRadius: BorderRadius.circular(5),
                                    style: ButtonVariance.card,
                                    onPressed: () async {
                                      if (mounted) {

                                        print("ID: ${choice.tmdbMedia.id} Type: ${choice.type}");
                                        context.pop();
                                        context.push('/${choice.type}/${choice.tmdbMedia.id}');
                                      }
                                    },

                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          SizedBox(
                                            width: 60,
                                            height: 100,
                                            child: ClipRRect(
                                              borderRadius: BorderRadiusGeometry.circular(8),
                                              child: CachedNetworkImage(imageUrl: choice.poster, fit: BoxFit.cover),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(choice.name),
                                              Row(
                                                spacing: 8,
                                                children: [
                                                  Chip(style: const ButtonStyle.outline(), child: Text(choice.type)),
                                                  Chip(style: const ButtonStyle.outline(), child: Text(choice.releaseInfo)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    );
                  },
                );

                return cacheWidget!;
              },
            ),
          ];
        },
      ),
    );
  }
}
