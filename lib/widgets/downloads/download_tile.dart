import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/utils/byte_format.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/widgets/downloads/download_context_menu.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadTile extends StatelessWidget {
  final DownloadEntry entry;
  const DownloadTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DownloadContextMenu(
      entry: entry,
      child: LibraryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 10,
              children: [
                Icon(
                  entry.status == DownloadStatus.done
                      ? LucideIcons.circleCheck
                      : LucideIcons.arrowDownToLine,
                  size: 20,
                  color: colors.mutedForeground,
                ),
                Expanded(
                  child: Text(
                    entry.displayTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(LucideIcons.trash),
                  onPressed: () => DownloadManager.remove(entry.id),
                ),
              ],
            ),
            if (entry.episodeLabel != null) Text(entry.episodeLabel!),
            if (entry.downloadedBytes > 0 || entry.totalBytes > 0)
              Text(
                '${formatBytes(entry.downloadedBytes)}${entry.totalBytes > 0 ? ' / ${formatBytes(entry.totalBytes)}' : ''}',
              ),
            if (entry.status == DownloadStatus.failed ||
                entry.status == DownloadStatus.unavailable)
              Wrap(
                spacing: 8,
                children: [
                  PetalButton.outline(
                    onPressed: () => DownloadManager.retry(entry.id),
                    child: const Text('Retry download'),
                  ),
                  PetalButton.ghost(
                    onPressed: () =>
                        DownloadManager.retry(entry.id, newSource: true),
                    child: const Text('Find new source'),
                  ),
                ],
              ),
            if (entry.status == DownloadStatus.queued ||
                entry.status == DownloadStatus.running)
              Wrap(
                spacing: 8,
                children: [
                  PetalButton.outline(
                    onPressed: () => DownloadManager.pause(entry.id),
                    child: const Text('Pause'),
                  ),
                  if (entry.status == DownloadStatus.queued)
                    PetalButton.ghost(
                      onPressed: () => DownloadManager.moveEarlier(entry.id),
                      child: const Text('Move earlier'),
                    ),
                ],
              ),
            if (entry.status == DownloadStatus.paused)
              PetalButton.outline(
                onPressed: () => DownloadManager.resume(entry.id),
                child: const Text('Resume download'),
              ),
            if (entry.status == DownloadStatus.running)
              LinearProgressIndicator(
                value: entry.progress == 0 ? null : entry.progress,
              ),
            Text(
              _statusText(entry),
              style: TextStyle(color: colors.mutedForeground),
            ),
            if (entry.status == DownloadStatus.done && entry.path != null)
              PetalButton.primary(
                onPressed: () => DownloadContextMenu.play(context, entry),
                child: const Text('Play'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusText(DownloadEntry entry) {
    switch (entry.status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.paused:
        return 'Paused — partial file kept';
      case DownloadStatus.running:
        return 'Downloading ${(entry.progress * 100).clamp(0, 100).round()}%';
      case DownloadStatus.done:
        return 'Saved on this device';
      case DownloadStatus.failed:
        return entry.error ?? 'Download failed';
      case DownloadStatus.unavailable:
        return 'No HTTP source available';
    }
  }
}
