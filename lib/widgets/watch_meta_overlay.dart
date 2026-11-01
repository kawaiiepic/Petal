import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class WatchMetaOverlay extends StatelessWidget {
  final String? episodeLabel;
  final String? durationLabel;
  final String? remainingLabel;

  const WatchMetaOverlay({
    super.key,
    this.episodeLabel,
    this.durationLabel,
    this.remainingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final left = [
      episodeLabel,
      durationLabel,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final right = remainingLabel?.trim() ?? '';
    if (left.isEmpty && right.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (left.isNotEmpty) _pill(left),
        const Spacer(),
        if (right.isNotEmpty)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: _pill(right, maxLines: 2),
            ),
          ),
      ],
    );
  }

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
