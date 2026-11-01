import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/stream_item.dart';
import 'package:petal/utils/watch_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadContextMenu extends StatelessWidget {
  final DownloadEntry entry;
  final Widget child;
  const DownloadContextMenu({
    super.key,
    required this.entry,
    required this.child,
  });

  static void play(BuildContext context, DownloadEntry entry) {
    if (entry.path == null || entry.status != DownloadStatus.done) return;
    final progress = WatchProgress.isWatched(entry.playbackProgress)
        ? 0
        : entry.playbackProgress;
    final route =
        '/player?media=${entry.tmdbId}${entry.isShow ? '&s=${entry.season}&e=${entry.episode}' : ''}&p=$progress';
    context.push(
      route,
      extra: StreamItem.localFile(
        path: entry.path!,
        title: entry.displayName,
        download: entry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ContextMenu(
    items: [
      if (entry.status == DownloadStatus.done && entry.path != null)
        MenuButton(
          leading: const Icon(LucideIcons.play),
          child: const Text('Play download'),
          onPressed: (_) => play(context, entry),
        ),
      MenuButton(
        leading: const Icon(LucideIcons.info),
        child: Text(entry.isShow ? 'View show' : 'View movie'),
        onPressed: (_) => context.push(
          '/${entry.isShow ? 'series' : 'movie'}?tmdb=${entry.tmdbId}',
        ),
      ),
      const MenuDivider(),
      MenuButton(
        leading: const Icon(LucideIcons.trash),
        child: const Text('Delete download'),
        onPressed: (_) async {
          try {
            await DownloadManager.remove(entry.id);
          } catch (_) {
            if (context.mounted)
              showToast(
                context: context,
                builder: (_, _) =>
                    const Text('Could not delete the downloaded file.'),
              );
          }
        },
      ),
    ],
    child: child,
  );
}
