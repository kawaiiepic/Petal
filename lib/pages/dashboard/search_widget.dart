import 'dart:async';
import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/api/trakt/models.dart';
import 'package:blssmpetal/api/trakt/trakt_class.dart';
import 'package:blssmpetal/api/trakt/trakt_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/episode_overview.dart';
import 'package:blssmpetal/pages/movie_overview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fuzzywuzzy/algorithms/token_sort.dart';
import 'package:fuzzywuzzy/applicable.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/ratios/partial_ratio.dart';

enum SearchType { seriesAndMovies, series, movies, actors }

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;
  String _currentQuery = "";

  List<CatalogItem> results = [];
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
        results = await StreamApi.searchCatalogItems(query, addons);
      } finally {
        loading = false;
        notifyListeners();
      }
    });
  }
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
    Widget? _cacheWidget;
    return Padding(
      padding: EdgeInsets.all(8),
      child: SearchAnchor(
        isFullScreen: false,
        viewHintText: 'Search TV Shows, Movies & more...',
        viewLeading: ValueListenableBuilder<SearchType>(
          valueListenable: searchTypeNotifier,
          builder: (context, type, _) {
            return PopupMenuButton<SearchType>(
              icon: Row(children: [Icon(Icons.filter_list), SizedBox(width: 6), Text(label(type))]),
              onSelected: (t) => searchTypeNotifier.value = t,
              itemBuilder: (context) => SearchType.values.map((type) => PopupMenuItem<SearchType>(value: type, child: Text(label(type)))).toList(),
            );
          },
        ),
        builder: (context, controller) {
          return SearchBar(
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

                if (_cacheWidget != null && searchModel._debounce != null && searchModel._debounce!.isActive) return _cacheWidget!;

                _cacheWidget = ValueListenableBuilder<SearchType>(
                  valueListenable: searchTypeNotifier,
                  builder: (context, searchType, _) {
                    return ListenableBuilder(
                      listenable: searchModel,
                      builder: (context, _) {
                        return Column(
                          children: extractTop(query: searchModel._currentQuery, choices: searchModel.results, limit: 10, cutoff: 80, getter: (x) => x.name)
                              .where((item) {
                                final choice = item.choice;

                                print("Text: ${searchModel._currentQuery}, Show: ${choice.name}, Score: ${item.score}");
                                switch (searchTypeNotifier.value) {
                                  case SearchType.series:
                                    return choice.type == "series";

                                  case SearchType.movies:
                                    return choice.type == "movie";

                                  case SearchType.seriesAndMovies:
                                    return choice.type == "series" || choice.type == "movie";

                                  case SearchType.actors:
                                    return choice.type == "actor";
                                }
                              })
                              .map((item) {
                                final choice = item.choice;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () async {
                                    if (mounted) {
                                      final searchSnapshot = await ApiCache.getSearch("imdb", choice.id, choice.type);
                                      final show = choice.type == "series";
                                      final item = show
                                          ? await TraktApi.fetchShowWithProgress(searchSnapshot.show!.ids.trakt)
                                          : await TraktApi.fetchMovie(searchSnapshot.movie!.ids.trakt.toString());
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (_) => show
                                      //         ? EpisodeOverview(item: item! as TraktWatchedShowWithProgress, selectedEpisode: null)
                                      //         : MovieOverview(item: item! as Movie),
                                      //   ),
                                      // );
                                    }
                                  },

                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    child: Row(children: [Text(choice.name), Text("(${choice.type})")]),
                                  ),
                                );
                              })
                              .toList(),
                        );
                      },
                    );
                  },
                );

                return _cacheWidget!;
              },
            ),
          ];
        },
      ),
    );
  }
}
