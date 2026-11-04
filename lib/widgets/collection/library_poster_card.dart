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
    return FutureBuilder(
      initialData: CollectionMetadata.peek(title.tmdbId, title.type),
      future: _metadata,
      builder: (context, snapshot) {
        final loading = !snapshot.hasData &&
            snapshot.connectionState != ConnectionState.done;
        final data = snapshot.data as dynamic;
        final path = snapshot.hasData ? data.posterPath as String? : null;
        final name = snapshot.hasData
            ? (isShow ? data.name : data.title) as String?
            : null;
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
                  totalEpisodes: isShow && snapshot.hasData
                      ? data.numberOfEpisodes as int?
                      : null,
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
