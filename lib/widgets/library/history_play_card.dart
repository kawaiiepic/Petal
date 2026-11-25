import 'package:go_router/go_router.dart';
import 'package:petal/api/api.dart';
import 'package:petal/api/collection_metadata.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/tmdb/tmdb_movie.dart';
import 'package:petal/models/tmdb/tmdb_show.dart';
import 'package:petal/utils/history_timeline.dart';
import 'package:petal/widgets/library/history_title_dialog.dart';
import 'package:petal/widgets/media/media_card.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class HistoryPlayCard extends StatefulWidget {
  final HistoryPlay play;
  const HistoryPlayCard({super.key, required this.play});

  @override
  State<HistoryPlayCard> createState() => _HistoryPlayCardState();
}

class _HistoryPlayCardState extends State<HistoryPlayCard> {
  late Future<Object> _metadata = _load();

  Future<Object> _load() => CollectionMetadata.get(
    widget.play.item.tmdbId, widget.play.item.mediaType,
  );

  @override
  void didUpdateWidget(covariant HistoryPlayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.play.item.tmdbId != widget.play.item.tmdbId ||
        oldWidget.play.item.mediaType != widget.play.item.mediaType) {
      _metadata = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final play = widget.play;
    final item = play.item;
    final episode = play.episode;
    return FutureBuilder<Object>(
      future: _metadata,
      initialData: CollectionMetadata.peek(item.tmdbId, item.mediaType),
      builder: (context, snapshot) {
        final title = CollectionHistoryEntry(item: item, metadata: snapshot.data).title;
        final path = switch (snapshot.data) {
          TmdbShow show => show.posterPath,
          TmdbMovie movie => movie.posterPath,
          _ => null,
        };
        final subtitle = episode == null
            ? 'Movie'
            : 'S${episode.season} · E${episode.episode}';
        final date = play.date?.toLocal();
        final time = date == null ? null :
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        final route = episode == null
            ? '/movie?tmdb=${item.tmdbId}'
            : '/episode?tmdb=${item.tmdbId}&s=${episode.season}&e=${episode.episode}';
        void manage() => showOverlay(
          context,
          DialogConfiguration(),
          builder: (_) => HistoryTitleDialog(
            tmdbId: item.tmdbId, type: item.mediaType, title: title,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Expanded(
              child: MediaCard(
                orientation: Orientation.portrait,
                label: '$title · $subtitle',
                imageUrl: path == null || path.isEmpty ? null : Api.proxyImage(
                  path.startsWith('http') ? path : 'https://image.tmdb.org/t/p/w342$path',
                ),
                isLoading: !snapshot.hasData && snapshot.connectionState != ConnectionState.done,
                showLogo: false,
                showProgress: false,
                showDefaultContextMenu: false,
                primaryActionLabel: 'View details',
                onTap: () => context.push(route),
                extraContextItems: [
                  MenuButton(
                    leading: const Icon(LucideIcons.history),
                    child: const Text('Manage history'),
                    onPressed: (_) => manage(),
                  ),
                ],
              ),
            ),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(time == null ? subtitle : '$subtitle · $time',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.mutedForeground)),
          ],
        );
      },
    );
  }
}
