import 'package:petal/widgets/media/artwork_caption.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchMetaOverlay extends StatelessWidget {
  final String? episodeLabel;
  final String? durationLabel;
  final String? remainingLabel;
  final bool playback;
  final double? progress;

  const WatchMetaOverlay({
    super.key,
    this.episodeLabel,
    this.durationLabel,
    this.remainingLabel,
    this.playback = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final left = [
      episodeLabel,
      durationLabel,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final right = remainingLabel?.trim() ?? '';
    if (playback) return _playback(left, right);
    if (left.isEmpty && right.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 6,
      children: [
        if (left.isNotEmpty)
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              heightFactor: 1,
              child: _pill(left),
            ),
          ),
        if (right.isNotEmpty)
          Expanded(
            flex: 2,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              heightFactor: 1,
              child: _pill(right, maxLines: 2),
            ),
          ),
      ],
    );
  }

  Widget _playback(String left, String right) => ArtworkCaption(
    child: Row(
      spacing: 6,
      children: [
        const Icon(BootstrapIcons.playFill, color: Colors.white, size: 15),
        if (progress case final value?)
          SizedBox(
            width: 28,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: ColoredBox(
                color: const Color(0x66FFFFFF),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: value.clamp(.08, 1),
                    heightFactor: 1,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: _captionText(left)),
        if (right.isNotEmpty)
          Expanded(child: _captionText(right, secondary: true)),
      ],
    ),
  );

  Widget _captionText(String text, {bool secondary = false}) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: secondary ? TextAlign.end : TextAlign.start,
    style: TextStyle(
      color: secondary ? const Color(0xFFD7D9DE) : Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _pill(String text, {int maxLines = 1}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE6101018),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }
}
