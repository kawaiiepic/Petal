import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/collection_metadata.dart';
import 'package:petal/models/library/library_title.dart';
import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:shadcn_flutter_skeletonizer/shadcn_flutter_skeletonizer.dart';

class LibraryPosterCard extends StatefulWidget {
  final LibraryTitle title;
  const LibraryPosterCard({super.key, required this.title});

  @override
  State<LibraryPosterCard> createState() => _LibraryPosterCardState();
}

class _LibraryPosterCardState extends State<LibraryPosterCard> {
  late Future<Object> _metadata;
  LibraryTitle get title => widget.title;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(LibraryPosterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title.tmdbId != title.tmdbId ||
        oldWidget.title.type != title.type) _load();
  }

  void _load() {
    _metadata = CollectionMetadata.get(title.tmdbId, title.type);
  }

  @override
  Widget build(BuildContext context) {
    final isShow = title.type == MediaType.show;
    return FutureBuilder<Object>(
      key: ValueKey((title.type, title.tmdbId)),
      initialData: CollectionMetadata.peek(title.tmdbId, title.type),
      future: _metadata,
      builder: (context, snapshot) {
        // FutureBuilder can retain the previous future's data while switching.
        // Validate both the media type and ID before reading any metadata.
        final raw = snapshot.data;
        final show = isShow && raw is TmdbShow && raw.id == title.tmdbId
            ? raw : null;
        final movie = !isShow && raw is TmdbMovie && raw.id == title.tmdbId
            ? raw : null;
        final loading = show == null && movie == null &&
            snapshot.connectionState != ConnectionState.done;
        final path = show?.posterPath ?? movie?.posterPath;
        final name = show?.name ?? movie?.title;
        final badge = title.rating == TitleRating.love
            ? 'Loved'
            : title.rating == TitleRating.like
            ? 'Liked'
            : 'Watchlist';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MediaCard(
                isLoading: loading,
                label: name,
                target: MediaCardTarget(
                  tmdbId: title.tmdbId,
                  type: title.type,
                  totalEpisodes: show?.numberOfEpisodes,
                ),
                imageUrl: path == null || path.isEmpty
                    ? null
                    : Api.proxyImage(
                        path.startsWith('http')
                            ? path
                            : 'https://image.tmdb.org/t/p/w342$path',
                      ),
                onTap: () => context.push(
                  isShow
                      ? '/series?tmdb=${title.tmdbId}'
                      : '/movie?tmdb=${title.tmdbId}',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name ?? (loading ? 'Loading title' : 'Title unavailable'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ).asSkeleton(enabled: loading),
            Text(
              badge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: .6),
              ),
            ),
          ],
        );
      },
    );
  }
}
