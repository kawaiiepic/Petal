import 'dart:async';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/router/router.dart';
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
  String _currentQuery = '';
  int _requestId = 0;

  String get currentQuery => _currentQuery;

  List<SearchResult> results = [];
  bool loading = false;

  Future<void> search(String query, List<Addon> addons) async {
    final trimmed = query.trim();
    _currentQuery = trimmed;

    final int thisRequestId = ++_requestId;

    if (trimmed.isEmpty) {
      results = [];
      loading = false;
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final raw = await StreamApi.searchCatalogItems(trimmed, addons);

      if (thisRequestId != _requestId) {
        return;
      }

      final enriched = raw.map((item) {
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
      }).toList();

      if (thisRequestId != _requestId) {
        return;
      }

      results = enriched;
    } finally {
      if (thisRequestId == _requestId) {
        loading = false;
        notifyListeners();
      }
    }
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
  }

  Future<void> _submitSearch() async {
    final addons = _addons;
    final query = _textController.text.trim();

    if (addons == null || query.isEmpty) {
      _overlayController.close();
      return;
    }

    _showSearchOverlay();
    await searchModel.search(query, addons);
  }

  void _openResult(SearchResult choice) {
    final type = choice.type == 'series' ? 'series' : 'movie';
    var id = choice.id;
    if (id.contains(':')) {
      id = id.split(':').first;
    }

    _overlayController.close();
    _textController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.appRouter.push('/$type?imdb=$id');
    });
  }

  void _showSearchOverlay() {
    if (!mounted) {
      return;
    }

    if (_overlayController.hasOpenOverlay) return;

    _overlayController.show(
      context,
      PopoverConfiguration(
        alignment: Alignment.bottomCenter,
        anchorAlignment: Alignment.topCenter,
        widthConstraint: PopoverConstraint.flexible,
        heightConstraint: PopoverConstraint.flexible,
        modal: false,
        consumeOutsideTaps: false,
        dismissBackdropFocus: false,
        barrierDismissable: true,
      ),
      builder: (context) => _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
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

          final matches = extractTop(
            query: searchModel.currentQuery,
            choices: filtered,
            limit: 10,
            cutoff: 50,
            getter: (x) => x.name,
          );

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
                    padding: const EdgeInsets.all(2),
                    child: Button.ghost(
                      leading: choice.type == 'movie' ? const Icon(LucideIcons.ticket) : const Icon(LucideIcons.tv),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${choice.name} // '
                        '${choice.type.toUpperCase()} // '
                        '${choice.releaseInfo}',
                      ),
                      onPressed: () => _openResult(choice),
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
          Expanded(
            child: TextField(
              controller: _textController,
              placeholder: const Text('Search TV Shows, Movies & more...'),
              onSubmitted: (_) => _submitSearch(),
              features: [
                const InputFeature.clear(visibility: InputFeatureVisibility.textNotEmpty),
                InputFeature.trailing(
                  IconButton.ghost(
                    icon: const Icon(LucideIcons.search),
                    onPressed: _submitSearch,
                  ),
                ),
              ],
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
    _textController.dispose();
    _overlayController.dispose();
    searchTypeNotifier.dispose();
    searchModel.dispose();

    super.dispose();
  }
}
