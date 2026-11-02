import 'package:petal/api/offline_progress_sync.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OfflineSyncCard extends StatefulWidget {
  const OfflineSyncCard({super.key});
  @override
  State<OfflineSyncCard> createState() => _OfflineSyncCardState();
}

class _OfflineSyncCardState extends State<OfflineSyncCard> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    OfflineProgressSync.instance.load();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted)
        showToast(
          context: context,
          builder: (_, _) => const Text('Could not update offline sync.'),
        );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final sync = OfflineProgressSync.instance;
    return ListenableBuilder(
      listenable: sync,
      builder: (_, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Sync offline watch progress')),
                  Switch(
                    value: sync.enabled,
                    onChanged: _busy
                        ? null
                        : (v) => _run(() => sync.setEnabled(v)),
                  ),
                ],
              ),
              const Text(
                'Optional. Future downloaded-playback updates upload for their original profile when online. Sign in and select a profile before watching offline. Playback stays offline; turning this off clears pending uploads.',
              ),
              Text('${sync.pending} pending updates'),
              if (sync.lastError != null) Text(sync.lastError!),
              if (sync.enabled)
                Button.outline(
                  onPressed: _busy ? null : () => _run(sync.sync),
                  child: Text(_busy ? 'Syncing…' : 'Sync now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
