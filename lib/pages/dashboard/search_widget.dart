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
import 'package:sizer/sizer.dart';

enum SearchType { seriesAndMovies, series, movies, actors }

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;
  String _currentQuery = "";
  int _requestId = 0; // NEW: tracks the latest search "generation"

  List<SearchResult> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    if (_currentQuery.trim() == query.trim()) return;
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _currentQuery = query;
      final int thisRequestId = ++_requestId; // claim this run's ticket

      if (query.isEmpty) {
        results = [];
        loading = false;
        notifyListeners();
        return;
      }

      loading = true;
      notifyListeners();

      try {
        final raw = (await StreamApi.searchCatalogItems(query, addons)).take(5);

        // A newer search started while we were awaiting — drop this one.
        if (thisRequestId != _requestId) return;

        final enriched = await Future.wait(
          raw.map((item) async {
            print("Searching: $query");
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
            );
          }),
        );

        // Check again after the second await gap before mutating state.
        if (thisRequestId != _requestId) return;

        results = enriched.whereType<SearchResult>().toList();
      } finally {
        if (thisRequestId == _requestId) {
          loading = false;
          notifyListeners();
        }
      }
    });
  }
}

class SearchResult extends CatalogItem {
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
  final material.SearchController _viewController = material.SearchController();

  List<Addon>? _addons;

  @override
  void initState() {
    super.initState();
    searchModel = SearchControllerModel();
    ApiCache.getAddons().then((addons) {
      if (mounted) setState(() => _addons = addons);
    });
  }

  @override
  void dispose() {
    _viewController.dispose();
    searchTypeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ValueListenableBuilder<SearchType>(
        valueListenable: searchTypeNotifier,
        builder: (context, searchType, _) {
          return material.SearchAnchor(
            searchController: _viewController,
            isFullScreen: false,
            viewLeading: material.PopupMenuButton<SearchType>(
              icon: Row(children: [Icon(Icons.filter_list), const SizedBox(width: 6), Text(searchType.name)]),
              onSelected: (t) => searchTypeNotifier.value = t,
              itemBuilder: (context) => SearchType.values.map((type) => material.PopupMenuItem<SearchType>(value: type, child: Text(type.name))).toList(),
            ),
            viewTrailing: [material.IconButton(icon: const Icon(Icons.close), onPressed: () => _viewController.closeView(null))],
            builder: (context, controller) {
              return material.SearchBar(
                controller: controller,
                hintText: 'Search TV Shows, Movies & more...',
                constraints: BoxConstraints(maxWidth: 70.w, minHeight: 48),
                onTap: () => controller.openView(),
                onChanged: (value) => controller.openView(),
              );
            },
            suggestionsBuilder: (context, controller) {
              final addons = _addons;
              if (addons == null) return [const SizedBox()];

              searchModel.search(controller.text, addons);

              // ✅ this single item subscribes directly to searchModel and
              // rebuilds itself whenever new results arrive — independent
              // of whether SearchAnchor re-invokes suggestionsBuilder.
              return [
                ListenableBuilder(
                  listenable: searchModel,
                  builder: (context, _) {
                    final filtered = searchModel.results.where((item) {
                      switch (searchType) {
                        case SearchType.series:
                          return item.type == "series";
                        case SearchType.movies:
                          return item.type == "movie";
                        case SearchType.seriesAndMovies:
                          return item.type == "series" || item.type == "movie";
                        case SearchType.actors:
                          return item.type == "actor";
                      }
                    }).toList();

                    final matches = extractTop(query: searchModel._currentQuery, choices: filtered, limit: 10, cutoff: 80, getter: (x) => x.name);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: matches.map((item) {
                        final choice = item.choice;
                        return Button(
                          onPressed: () async {
                            if (!mounted) return;
                            final search = await ApiCache.getTmdbSearch(choice.id);
                            final tmdbResults = choice.type == "series" ? search.tv.first : search.movies.first;
                            print(tmdbResults.id);
                            context.pop();
                            context.push('/${choice.type}/${tmdbResults.id}');
                          },
                          style: ButtonVariance.text,
                          child: Text('${choice.name} // ${choice.type} // ${choice.releaseInfo}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ];
            },
          );
        },
      ),
    );
  }
}
