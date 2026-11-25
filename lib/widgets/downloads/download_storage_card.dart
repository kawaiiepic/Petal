import 'dart:async';

import 'package:petal/api/download_manager.dart';
import 'package:petal/models/downloads/download_storage.dart';
import 'package:petal/utils/byte_format.dart';
import 'package:petal/widgets/library/library_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class DownloadStorageCard extends StatefulWidget {
  const DownloadStorageCard({super.key});

  @override
  State<DownloadStorageCard> createState() => _DownloadStorageCardState();
}

class _DownloadStorageCardState extends State<DownloadStorageCard> {
  DownloadStorage? _storage;
  bool _hasResult = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _readStorage();
  }

  void _readStorage() {
    var finished = false;
    void finish(DownloadStorage? storage) {
      if (finished || !mounted) return;
      finished = true;
      _timer?.cancel();
      setState(() {
        _storage = storage;
        _hasResult = true;
      });
      _timer = Timer(const Duration(seconds: 5), _readStorage);
    }

    // A stalled query must not replace a later reading or keep the card loading.
    _timer = Timer(const Duration(seconds: 8), () => finish(null));
    DownloadManager.storage().then(finish, onError: (Object _) => finish(null));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = _storage;
    final free = storage?.freeBytes;
    final muted = Theme.of(context).colorScheme.mutedForeground;
    return LibraryPanel(
      child: Row(
        spacing: 14,
        children: [
          Icon(LucideIcons.hardDrive, size: 24, color: muted),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                const Text(
                  'Device storage',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  storage != null
                      ? '${formatBytes(storage.usedBytes)} used by downloads'
                      : _hasResult
                      ? 'Download size unavailable'
                      : 'Calculating download size…',
                ),
                if (storage != null)
                  Text(
                    free == null
                        ? 'Free space unavailable'
                        : '${formatBytes(free)} free on this device',
                    style: TextStyle(color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
