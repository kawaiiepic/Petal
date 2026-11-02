import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:petal/utils/media_formatting.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Local player diagnostics. Mounted only while open; no metadata/network calls.
class PlayerDebugOverlay extends StatefulWidget {
  final Player player;
  final VoidCallback onClose;
  const PlayerDebugOverlay({
    super.key,
    required this.player,
    required this.onClose,
  });

  @override
  State<PlayerDebugOverlay> createState() => _PlayerDebugOverlayState();
}

class _PlayerDebugOverlayState extends State<PlayerDebugOverlay> {
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    _refresh = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  String text(Object? value) =>
      value == null || value.toString().trim().isEmpty ? '—' : value.toString();
  String bitrate(num? value) => value == null || !value.isFinite || value <= 0
      ? '—'
      : '${(value / 1000).toStringAsFixed(0)} kb/s';

  @override
  Widget build(BuildContext context) {
    final state = widget.player.state;
    final playlist = state.playlist;
    final media = playlist.index >= 0 && playlist.index < playlist.medias.length
        ? playlist.medias[playlist.index]
        : null;
    final uri = media == null ? null : Uri.tryParse(media.uri);
    final local = media?.extras?['offline'] == true || uri?.scheme == 'file';
    final video =
        (state.track.video.id == 'auto'
            ? state.tracks.video
                  .where((track) => track.id != 'auto' && track.id != 'no')
                  .singleOrNull
            : state.tracks.video
                  .where((track) => track.id == state.track.video.id)
                  .firstOrNull) ??
        state.track.video;
    final audio =
        (state.track.audio.id == 'auto'
            ? state.tracks.audio
                  .where((track) => track.id != 'auto' && track.id != 'no')
                  .singleOrNull
            : state.tracks.audio
                  .where((track) => track.id == state.track.audio.id)
                  .firstOrNull) ??
        state.track.audio;
    final width = state.videoParams.w ?? state.width;
    final height = state.videoParams.h ?? state.height;
    final ahead = state.buffer > state.position
        ? state.buffer - state.position
        : Duration.zero;
    final status = state.buffering
        ? 'Buffering'
        : state.completed
        ? 'Finished'
        : state.playing
        ? 'Playing'
        : 'Paused';
    final rows = <(String, String)>[
      (
        'Source',
        media == null
            ? 'No media'
            : local
            ? 'Local file'
            : 'Network stream',
      ),
      ('State', status),
      (
        'Position',
        '${MediaFormatting.fmt(state.position)} / ${MediaFormatting.fmt(state.duration)}',
      ),
      ('Buffered until', MediaFormatting.fmt(state.buffer)),
      ('Buffer ahead', '${(ahead.inMilliseconds / 1000).toStringAsFixed(1)} s'),
      (
        'Media buffered to',
        state.duration > Duration.zero
            ? '${(state.buffer.inMilliseconds / state.duration.inMilliseconds * 100).clamp(0, 100).toStringAsFixed(1)}%'
            : '—',
      ),
      (
        'Buffer readiness',
        state.bufferingPercentage.isFinite
            ? '${state.bufferingPercentage.toStringAsFixed(0)}%'
            : '—',
      ),
      (
        'Speed / volume',
        '${state.rate.toStringAsFixed(2)}× / ${state.volume.toStringAsFixed(0)}%',
      ),
      (
        'Resolution',
        width == null || height == null ? '—' : '$width × $height',
      ),
      ('Video codec', text(video.codec)),
      ('Video decoder', text(video.decoder)),
      ('Source FPS', video.fps == null ? '—' : video.fps!.toStringAsFixed(3)),
      ('Video bitrate', bitrate(video.bitrate)),
      ('Pixel format', text(state.videoParams.pixelformat)),
      ('Hardware pixel format', text(state.videoParams.hwPixelformat)),
      (
        'Color / transfer',
        '${text(state.videoParams.primaries)} / ${text(state.videoParams.gamma)}',
      ),
      ('Audio codec', text(audio.codec)),
      ('Audio bitrate', bitrate(state.audioBitrate ?? audio.bitrate)),
      ('Audio format', text(state.audioParams.format)),
      (
        'Sample rate',
        state.audioParams.sampleRate == null
            ? '—'
            : '${state.audioParams.sampleRate} Hz',
      ),
      (
        'Channels',
        text(state.audioParams.hrChannels ?? state.audioParams.channels),
      ),
      ('Audio language', text(audio.language)),
      (
        'Subtitles',
        state.track.subtitle.id == 'no'
            ? 'Off'
            : text(
                state.track.subtitle.title ??
                    state.track.subtitle.language ??
                    state.track.subtitle.id,
              ),
      ),
    ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onDoubleTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xE6101018),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Playback diagnostics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  tooltip: (_) => const Text('Close diagnostics'),
                  child: IconButton(
                    variance: ButtonVariance.ghost,
                    onPressed: widget.onClose,
                    icon: const Icon(
                      LucideIcons.x,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                row.$1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: .65),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 6,
                              child: Text(
                                row.$2,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
