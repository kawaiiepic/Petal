import 'package:petal/widgets/downloads/download_storage_card.dart';
import 'package:petal/api/download_manager.dart';
import 'package:petal/widgets/back_button.dart';
import 'package:petal/widgets/downloads/download_tile.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      headers: const [
        AppBar(leading: [BackButton()], title: Text('Downloads')),
      ],
      child: Column(
        children: [
          const DownloadStorageCard(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Text('Download on Wi-Fi only')),
                ValueListenableBuilder(
                  valueListenable: DownloadManager.wifiOnly,
                  builder: (context, value, _) => Switch(
                    value: value,
                    onChanged: DownloadManager.setWifiOnly,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder(
            valueListenable: DownloadManager.waitingForWifi,
            builder: (context, waiting, _) => waiting
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'Waiting for Wi-Fi. Resume automatically when connected.',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
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
                  itemBuilder: (context, index) =>
                      DownloadTile(entry: items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
