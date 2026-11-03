import 'package:petal/widgets/media/media_artwork_placeholder.dart';
import 'package:go_router/go_router.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/models/media_card_target.dart';
import 'package:petal/models/media_type.dart';
import 'package:petal/widgets/downloads/download_context_menu.dart';
import 'package:petal/widgets/home_section.dart';
import 'package:petal/widgets/media/in_progress_indicator.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadsShelf extends StatefulWidget {
  const DownloadsShelf({super.key});

  @override
  State<DownloadsShelf> createState() => _DownloadsShelfState();
}

class _DownloadsShelfState extends State<DownloadsShelf> {
  bool _loading = true;

  Future<void> _load() async {
    try {
      await DownloadManager.load();
      DownloadManager.refreshMetadata().catchError((Object _) {});
    } catch (_) {
      // Finish loading even when the local download index is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: DownloadManager.items,
      builder: (context, items, _) {
        if (items.isEmpty && _loading) {
          return HomeSection(
            title: 'Downloads',
            child: Column(
              children: List.generate(3, (_) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 48,
                  child: MediaArtworkPlaceholder(loading: true),
                ),
              )),
            ),
          );
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return HomeSection(
          title: 'Downloads',
          trailing: Button.ghost(
            onPressed: () => context.push('/downloads'),
            child: const Text('See all'),
          ),
          child: Column(
            children: [
              for (final entry in items.take(4))
                DownloadContextMenu(
                  entry: entry,
                  child: Button.ghost(
                    alignment: Alignment.centerLeft,
                    onPressed: () => entry.status == DownloadStatus.done
                        ? DownloadContextMenu.play(context, entry)
                        : context.push('/downloads'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.status == DownloadStatus.done
                                ? LucideIcons.check
                                : LucideIcons.download,
                          ),
                          InProgressIndicator(
                            target: MediaCardTarget(
                              tmdbId: entry.tmdbId,
                              type: entry.isShow
                                  ? MediaType.show
                                  : MediaType.movie,
                            ),
                            localProgress: entry.playbackProgress,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _label(entry),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
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
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.queued:
        return 'Queued';
    }
  }
}
