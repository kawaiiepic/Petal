import 'package:petal/api/backend/backend_cache.dart';
import 'package:petal/api/tmdb/tmdb.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/shelf_item.dart';
import 'package:petal/widgets/poster_shelf.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BecauseYouWatchedShelf extends StatefulWidget {
  const BecauseYouWatchedShelf({super.key});

  @override
  State<BecauseYouWatchedShelf> createState() => _BecauseYouWatchedShelfState();
}

class _BecauseYouWatchedShelfState extends State<BecauseYouWatchedShelf> {
  Future<List<ShelfItem>>? _future;
  String _title = 'Because you watched';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ShelfItem>> _load() async {
    await BackendCache.fetchWatchHistory();
    final history = [...BackendCache.watchHistory.value]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (history.isEmpty) return const [];
    final seed = history.first;
    try {
      if (seed.mediaType == MediaType.show) {
        final show = await TMDB.tvShow(seed.tmdbId);
        _title = 'Because you watched ${show.name}';
        final recs = show.recommendations?.results.take(12) ?? const [];
        return recs
            .map((r) => ShelfItem(tmdbId: r.id, type: MediaType.show))
            .toList();
      }
      final movie = await TMDB.movie(seed.tmdbId);
      _title = 'Because you watched ${movie.title}';
      final recs = movie.recommendations?.results.take(12) ?? const [];
      return recs
          .map((r) => ShelfItem(tmdbId: r.id, type: MediaType.movie))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) =>
          PosterShelf(
            title: _title,
            items: snapshot.data ?? const [],
            loading: snapshot.connectionState != ConnectionState.done,
          ),
    );
  }
}
