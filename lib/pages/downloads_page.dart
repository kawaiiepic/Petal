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
    DownloadManager.refreshMetadata();
  }

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
            itemBuilder: (context, index) => DownloadTile(entry: items[index]),
          );
        },
      ),
    );
  }
}
