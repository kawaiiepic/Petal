import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

final _localAddon = Addon(
  id: 'local',
  userId: '',
  manifestUrl: '',
  baseUrl: '',
  forced: 0,
);

class DownloadTile extends StatelessWidget {
  final DownloadEntry entry;
  const DownloadTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton.ghost(
                  icon: const Icon(LucideIcons.trash),
                  onPressed: () => DownloadManager.remove(entry.id),
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
                onPressed: () {
                  final extra = StreamItem(
                    name: entry.title,
                    title: entry.title,
                    url: 'file://${entry.path}',
                    external: false,
                    addon: _localAddon,
                  );
                  if (entry.season != null) {
                    context.push(
                      '/player?media=${entry.tmdbId}&s=${entry.season}&e=${entry.episode}',
                      extra: extra,
                    );
                  } else {
                    context.push('/player?media=${entry.tmdbId}', extra: extra);
                  }
                },
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
