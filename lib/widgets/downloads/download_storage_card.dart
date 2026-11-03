import 'dart:async';

import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_storage.dart';
import 'package:petal/utils/byte_format.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadStorageCard extends StatefulWidget {
  const DownloadStorageCard({super.key});
  @override
  State<DownloadStorageCard> createState() => _DownloadStorageCardState();
}

class _DownloadStorageCardState extends State<DownloadStorageCard> {
  late Future<DownloadStorage> _storage;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _storage = DownloadManager.storage();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _storage = DownloadManager.storage());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DownloadStorage>(
    future: _storage,
    builder: (context, snapshot) => Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Downloads: ${snapshot.hasData ? formatBytes(snapshot.data!.usedBytes) : '…'} used',
              ),
              Text(
                'Device free space: ${snapshot.data?.freeBytes == null ? 'Unavailable' : formatBytes(snapshot.data!.freeBytes!)}',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
