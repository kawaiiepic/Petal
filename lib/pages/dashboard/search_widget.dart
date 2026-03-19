import 'dart:async';
import 'package:blssmpetal/api/api_cache.dart';
import 'package:blssmpetal/api/stream_helper.dart';
import 'package:blssmpetal/models/addon.dart';
import 'package:blssmpetal/models/catalog_item.dart';
import 'package:blssmpetal/pages/overview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum SearchType { seriesAndMovies, series, movies, actors }

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;

  List<CatalogItem> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.length < 3) {
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

                return ValueListenableBuilder<SearchType>(
                  valueListenable: searchTypeNotifier,
                  builder: (context, searchType, _) {
                    return ListenableBuilder(
                      listenable: searchModel,
                      builder: (context, _) {
                        return Column(
                          children: searchModel.results
                              .where((item) {
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
                              })
                              .map((item) {
                                return Container(
                                  padding: EdgeInsets.all(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () async {
                                      if (mounted) {
                                        final catalogItem = await StreamApi.fetchCatalogItem(item);
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => OverviewPage(item: catalogItem!)));
                                      }
                                    },
                                    child: Tooltip(
                                      message: item.name,
                                      child: Row(
                                        children: [
                                          Ink(
                                            height: 100,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(image: CachedNetworkImageProvider(item.poster), fit: BoxFit.cover),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),

                                          Container(width: 20),

                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            spacing: 8,
                                            children: [
                                              Text(item.name),
                                              Row(
                                                spacing: 8,
                                                children: [
                                                  Chip(label: Text(item.type)),
                                                  Chip(label: Text(item.releaseInfo)),
                                                ],
                                              ),
                                              Text(item.genres.join(', ')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ];
        },
      ),
    );
  }
}
