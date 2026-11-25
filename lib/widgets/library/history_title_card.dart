import 'package:petal/api/collection_metadata.dart';
import 'package:petal/models/library/collection_history_entry.dart';
import 'package:petal/models/watch_history/watch_history_item.dart';
import 'package:petal/widgets/collection/collection_card.dart';
import 'package:petal/widgets/library/history_title_dialog.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Loads artwork on demand as the history shelf scrolls into view.
class HistoryTitleCard extends StatefulWidget {
  const HistoryTitleCard({super.key, required this.item});

  final WatchHistoryItem item;

  @override
  State<HistoryTitleCard> createState() => _HistoryTitleCardState();
}

class _HistoryTitleCardState extends State<HistoryTitleCard> {
  late Future<Object> _metadata = _loadMetadata();

  Future<Object> _loadMetadata() =>
      CollectionMetadata.get(widget.item.tmdbId, widget.item.mediaType);

  @override
  void didUpdateWidget(covariant HistoryTitleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.tmdbId != widget.item.tmdbId ||
        oldWidget.item.mediaType != widget.item.mediaType) {
      _metadata = _loadMetadata();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return FutureBuilder<Object>(
      initialData: CollectionMetadata.peek(item.tmdbId, item.mediaType),
      future: _metadata,
      builder: (context, snapshot) {
        final entry = CollectionHistoryEntry(
          item: item,
          metadata: snapshot.data,
        );
        return CollectionCard(
          entry: entry,
          onManageHistory: () => showOverlay(
            context,
            DialogConfiguration(),
            builder: (_) => HistoryTitleDialog(
              tmdbId: item.tmdbId,
              type: item.mediaType,
              title: entry.title,
            ),
          ),
        );
      },
    );
  }
}
