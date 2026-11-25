import 'package:go_router/go_router.dart';
import 'package:petal/api/collection_metadata.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/api/api.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/utils/history_timeline.dart';
import 'package:petal/widgets/media/media_artwork.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PublicHistoryCard extends StatefulWidget {
  const PublicHistoryCard({super.key, required this.play});
  final HistoryPlay play;
  @override
  State<PublicHistoryCard> createState() => _PublicHistoryCardState();
}

class _PublicHistoryCardState extends State<PublicHistoryCard> {
  late Future<Object> _metadata;
  @override
  void initState() {
    super.initState();
    final item = widget.play.item;
    _metadata = CollectionMetadata.get(item.tmdbId, item.mediaType);
  }
  @override
  Widget build(BuildContext context) {
    final play = widget.play;
    final item = play.item;
    final episode = play.episode;
    return FutureBuilder<Object>(future: _metadata,
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        final title = CollectionHistoryEntry(item: item, metadata: metadata).title;
        final poster = switch (metadata) {
          TmdbMovie movie => movie.posterPath,
          TmdbShow show => show.posterPath,
          _ => null,
        };
        return GestureDetector(behavior: HitTestBehavior.opaque,
          onTap: () => context.push(episode != null
            ? '/episode?tmdb=${item.tmdbId}&s=${episode.season}&e=${episode.episode}'
            : '/${item.mediaType == MediaType.movie ? 'movie' : 'series'}?tmdb=${item.tmdbId}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: double.infinity, child: MediaArtwork(imageUrl: poster == null ? null :
                Api.proxyImage('https://image.tmdb.org/t/p/w342$poster'))))),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(episode == null ? 'Movie' : 'S${episode.season} · E${episode.episode}',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground)),
          ]),
        );
      });
  }
}
