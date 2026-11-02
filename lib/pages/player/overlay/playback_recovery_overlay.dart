import 'package:petal/models/stream_item.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PlaybackRecoveryOverlay extends StatelessWidget {
  final VoidCallback retry, findSources, close;
  final ValueChanged<StreamItem> choose;
  final List<StreamItem>? sources;
  final bool offline, loading;
  const PlaybackRecoveryOverlay({
    super.key,
    required this.retry,
    required this.findSources,
    required this.close,
    required this.choose,
    required this.offline,
    required this.loading,
    this.sources,
  });
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xE6101018),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const Icon(LucideIcons.triangleAlert, size: 32),
                const Text(
                  'Playback interrupted',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Your position, volume, and playback preferences are kept.',
                  textAlign: TextAlign.center,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Button.primary(
                      onPressed: loading ? null : retry,
                      child: const Text('Retry source'),
                    ),
                    if (!offline)
                      Button.outline(
                        onPressed: loading ? null : findSources,
                        child: const Text('Choose another source'),
                      ),
                    Button.ghost(
                      onPressed: close,
                      child: const Text('Close player'),
                    ),
                  ],
                ),
                if (loading) const CircularProgressIndicator(),
                if (sources != null && sources!.isEmpty)
                  const Text(
                    'No other playable sources found. Retry or check your addons.',
                  ),
                if (sources != null)
                  for (final source in sources!)
                    Button.outline(
                      onPressed: () => choose(source),
                      child: Text(
                        '${source.name}\n${source.title}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
