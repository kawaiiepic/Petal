import 'package:petal/api/api_cache.dart';
import 'package:petal/api/stream_helper.dart';
import 'package:petal/models/catalog_item.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/catalog/catalog_item_widget.dart';
import 'package:petal/widgets/connection_error.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late Future<List<CatalogItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(widget.query);
  }

  @override
  void didUpdateWidget(covariant SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = _load(widget.query);
    });
  }

  Future<List<CatalogItem>> _load(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final addons = await ApiCache.getAddons();
    final raw = await StreamApi.searchCatalogItems(trimmed, addons);

    final seen = <String>{};
    final items = <CatalogItem>[];
    for (final item in raw) {
      if (item.type != 'movie' && item.type != 'series') continue;
      if (!seen.add('${item.type}:${item.id}')) continue;
      items.add(item);
    }
    return items;
  }

  int _columns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 3;
    if (width < 700) return 4;
    if (width < 1100) return 5;
    return 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          leading: [BackButton()],
          title: Text(widget.query.trim().isEmpty ? 'Search' : widget.query.trim()),
        ),
      ],
      child: FutureBuilder<List<CatalogItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ConnectionErrorView(error: snapshot.error, onRetry: _reload);
          }

          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns(context),
              childAspectRatio: 2 / 3.15,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              return CatalogItemWidget(catalogItem: items[index]);
            },
          );
        },
      ),
    );
  }
}
