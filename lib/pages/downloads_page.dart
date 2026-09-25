import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/addon.dart';
import 'package:petal/models/stream.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

final _localAddon = Addon(id: 'local', userId: '', manifestUrl: '', baseUrl: '', forced: 0);

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: const [
        AppBar(leading: [BackButton()], title: Text('Downloads')),
      ],
      child: ValueListenableBuilder(
        valueListenable: DownloadManager.items,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(child: Text('Nothing downloaded yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _DownloadTile(entry: items[index]),
          );
        },
      ),
    );
  }
}

class DownloadsShelf extends StatelessWidget {
  const DownloadsShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DownloadManager.items,
      builder: (context, items, _) {
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Downloads',
          trailing: Button.ghost(onPressed: () => context.push('/downloads'), child: const Text('See all')),
          child: Column(
            children: [
              for (final entry in items.take(4))
                Button.ghost(
                  alignment: Alignment.centerLeft,
                  onPressed: () => context.push('/downloads'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(entry.status == DownloadStatus.done ? LucideIcons.check : LucideIcons.download),
                        const SizedBox(width: 8),
                        Expanded(child: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(_label(entry), style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _label(DownloadEntry entry) {
    switch (entry.status) {
      case DownloadStatus.running:
        return '${(entry.progress * 100).clamp(0, 100).round()}%';
      case DownloadStatus.done:
        return 'Ready';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.unavailable:
        return 'No source';
      case DownloadStatus.queued:
        return 'Queued';
    }
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadEntry entry;
  const _DownloadTile({required this.entry});

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
                Expanded(child: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton.ghost(icon: const Icon(LucideIcons.trash), onPressed: () => DownloadManager.remove(entry.id)),
              ],
            ),
            if (entry.status == DownloadStatus.running) LinearProgressIndicator(value: entry.progress == 0 ? null : entry.progress),
            Text(_statusText(entry), style: TextStyle(color: Colors.white.withValues(alpha: 0.65))),
            if (entry.status == DownloadStatus.done && entry.path != null)
              Button.primary(
                onPressed: () {
                  final extra = StreamItem(name: entry.title, title: entry.title, url: 'file://${entry.path}', external: false, addon: _localAddon);
                  if (entry.season != null) {
                    context.push('/player?media=${entry.tmdbId}&s=${entry.season}&e=${entry.episode}', extra: extra);
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
