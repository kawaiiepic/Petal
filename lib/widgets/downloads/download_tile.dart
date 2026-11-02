import 'package:petal/utils/byte_format.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/widgets/downloads/download_context_menu.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadTile extends StatelessWidget {
  final DownloadEntry entry;
  const DownloadTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return DownloadContextMenu(
      entry: entry,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
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
                    Button.outline(
                      onPressed: () => DownloadManager.retry(entry.id),
                      child: const Text('Retry download'),
                    ),
                    Button.ghost(
                      onPressed: () =>
                          DownloadManager.retry(entry.id, newSource: true),
                      child: const Text('Find new source'),
                    ),
                  ],
                ),
              if (entry.status == DownloadStatus.running)
                LinearProgressIndicator(
                  value: entry.progress == 0 ? null : entry.progress,
                ),
              Text(
                _statusText(entry),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              ),
              if (entry.status == DownloadStatus.done && entry.path != null)
                Button.primary(
                  onPressed: () => DownloadContextMenu.play(context, entry),
                  child: const Text('Play'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(DownloadEntry entry) {
    switch (entry.status) {
      case DownloadStatus.queued:
        return 'Waiting for a source';
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
