import 'package:petal/widgets/library/library_page_frame.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_entry.dart';
import 'package:petal/models/downloads/download_status.dart';
import 'package:petal/widgets/downloads/download_storage_card.dart';
import 'package:petal/widgets/downloads/download_tile.dart';
import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:petal/widgets/library/library_page_header.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  @override
  void initState() {
    super.initState();
    DownloadManager.load().then((_) => DownloadManager.refreshMetadata());
  }

  @override
  Widget build(BuildContext context) => LibraryPageFrame(
    header: const LibraryPageHeader(
        title: 'Downloads',
        description:
            'Manage offline playback and see what’s saved on this device.',
        icon: LucideIcons.download,
        showAccount: true,
      ),
    child: ValueListenableBuilder(
      valueListenable: DownloadManager.items,
      builder: (context, items, _) {
        final saved = items
            .where((item) => item.status == DownloadStatus.done)
            .toList();
        final queue = items
            .where((item) => item.status != DownloadStatus.done)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const DownloadStorageCard(),
            const SizedBox(height: 8),
            LibraryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      const Icon(LucideIcons.wifi, size: 20),
                      const Expanded(child: Text('Download on Wi-Fi only')),
                      ValueListenableBuilder(
                        valueListenable: DownloadManager.wifiOnly,
                        builder: (context, value, _) => PetalSwitch(
                          value: value,
                          onChanged: DownloadManager.setWifiOnly,
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: DownloadManager.waitingForWifi,
                    builder: (context, waiting, _) => waiting
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Waiting for Wi-Fi. Downloads will resume automatically.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .mutedForeground,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            ..._group('Download queue', queue),
            ..._group('Available offline', saved),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: LibraryPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Icon(LucideIcons.download, size: 22),
                      Text(
                        'Nothing downloaded yet.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('Download a movie or episode to watch it offline.'),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Iterable<Widget> _group(String label, List<DownloadEntry> entries) sync* {
    if (entries.isEmpty) return;
    yield Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Semantics(
        header: true,
        child: Row(
          spacing: 10,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SecondaryBadge(child: Text('${entries.length}')),
          ],
        ),
      ),
    );
    for (final entry in entries) {
      yield Padding(
        key: ValueKey(entry.id),
        padding: const EdgeInsets.only(bottom: 8),
        child: DownloadTile(entry: entry),
      );
    }
  }
}
