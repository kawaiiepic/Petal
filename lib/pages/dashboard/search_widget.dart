import 'dart:async';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

enum SearchType {
  seriesAndMovies('Series & Movies'),
  series('Series'),
  movies('Movies'),
  actors('Actors');

  final String title;

  const SearchType(this.title);
}

class SearchControllerModel extends ChangeNotifier {
  Timer? _debounce;
  String _currentQuery = '';
  int _requestId = 0;

  List<SearchResult> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    if (_currentQuery.trim() == query.trim()) {
      return;
    }

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _currentQuery = query;

      final int thisRequestId = ++_requestId;

      if (query.isEmpty) {
        results = [];
        loading = false;
        notifyListeners();
        return;
      }

      loading = true;
      notifyListeners();

      try {
        final raw = await StreamApi.searchCatalogItems(query, addons);

        if (thisRequestId != _requestId) {
          return;
        }

        final enriched = await Future.wait(
          raw.map((item) async {
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

        if (thisRequestId != _requestId) {
          return;
        }

        results = enriched.whereType<SearchResult>().toList();
      } finally {
        if (thisRequestId == _requestId) {
          loading = false;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
  late final SearchControllerModel searchModel;

  final ValueNotifier<SearchType> searchTypeNotifier = ValueNotifier(SearchType.seriesAndMovies);

  final TextEditingController _textController = TextEditingController();

  final OverlayController _overlayController = OverlayController();

  List<Addon>? _addons;

  @override
  void initState() {
    super.initState();

    searchModel = SearchControllerModel();

    ApiCache.getAddons().then((addons) {
      if (!mounted) return;

      setState(() {
        _addons = addons;
      });
    });

    _textController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final addons = _addons;

    if (addons == null) {
      return;
    }

    final query = _textController.text;

    searchModel.search(query, addons);

    if (query.isEmpty) {
      _overlayController.close();
      return;
    }

    _showSearchOverlay();
  }

  void _showSearchOverlay() {
    if (!mounted || _textController.text.isEmpty) {
      return;
    }

    _overlayController.show(
      context,
      PopoverConfiguration(
        alignment: Alignment.bottomCenter,
        anchorAlignment: Alignment.topCenter,
        widthConstraint: PopoverConstraint.flexible,
        heightConstraint: PopoverConstraint.flexible,
        builder: (context) {
          return _buildSearchResults(context);
        },
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 50.w, maxHeight: 30.h, minWidth: 50.w, minHeight: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.card,
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: ListenableBuilder(
        listenable: searchModel,
        builder: (context, _) {
          if (searchModel.loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final searchType = searchTypeNotifier.value;

          final filtered = searchModel.results.where((item) {
            switch (searchType) {
              case SearchType.series:
                return item.type == 'series';

              case SearchType.movies:
                return item.type == 'movie';

              case SearchType.seriesAndMovies:
                return item.type == 'series' || item.type == 'movie';

              case SearchType.actors:
                return item.type == 'actor';
            }
          }).toList();

          final matches = extractTop(query: searchModel._currentQuery, choices: filtered, limit: 10, cutoff: 80, getter: (x) => x.name);

          if (matches.isEmpty) {
            return const Padding(padding: EdgeInsets.all(16), child: Text('No results found.'));
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: matches.map((item) {
                  final choice = item.choice;
                  return Padding(
                    padding: EdgeInsetsGeometry.all(2),
                    child: Button.ghost(
                      leading: choice.type == "movie" ? Icon(Icons.local_movies) : Icon(Icons.movie),
                      alignment: Alignment.center,
                      child: Text(
                        '${choice.name} // '
                        '${choice.type.toUpperCase()} // '
                        '${choice.releaseInfo}',
                      ),
                      onPressed: () {
                        _overlayController.close();
                        context.push('/${choice.type}?imdb=${choice.id}');
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(SearchType searchType) {
    return Container(
      constraints: BoxConstraints(minHeight: 20, maxWidth: 50.w),
      child: Row(
        children: [
          // Padding(padding: const EdgeInsets.only(left: 4), child: _buildTypeMenu(searchType)),
          Expanded(
            child: TextField(
              onTap: _showSearchOverlay,
              features: [
                InputFeature.leading(
                  Select<SearchType>(
                    // How to render each selected item as text in the field.
                    padding: EdgeInsets.fromLTRB(12, 2, 12, 2),
                    borderRadius: BorderRadius.circular(8),
                    itemBuilder: (context, item) {
                      return Text(item.title);
                    },
                    // Limit the popup size so it doesn't grow too large in the docs view.
                    popupConstraints: const BoxConstraints(maxHeight: 300, maxWidth: 200),
                    onChanged: (value) {
                      setState(() {
                        // Save the currently selected value (or null to clear).
                        if (value == null) return;
                        searchTypeNotifier.value = value;
                      });
                    },
                    // The current selection bound to this field.
                    value: searchTypeNotifier.value,
                    placeholder: const Text('Media Type'),
                    popup: SelectPopup(
                      items: SelectItemList(
                        children: SearchType.values
                            .map(
                              (v) => SelectItemButton(
                                value: v,
                                child: Text(v.title, style: TextStyle(fontSize: 12)),
                              ),
                            )
                            .toList(),
                      ),
                    ).call,
                  ),
                ),
                const InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
                // Hint shows a small tooltip-like popup for the input field.
                InputFeature.hint(
                  popupBuilder: (context) {
                    return const TooltipContainer(child: Text('This is for your username'));
                  },
                ),
              ],
              controller: _textController,
              placeholder: const Text('Search TV Shows, Movies & more...'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ValueListenableBuilder<SearchType>(
        valueListenable: searchTypeNotifier,
        builder: (context, searchType, _) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 60.w),
            child: _buildSearchField(searchType),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textController.removeListener(_onSearchChanged);
    _textController.dispose();
    _overlayController.dispose();
    searchTypeNotifier.dispose();
    searchModel.dispose();

    super.dispose();
  }
}
