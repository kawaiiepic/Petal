import 'package:petal/pages/player/overlay/player_glass_panel.dart';
import 'package:petal/api/playback_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SubtitleAudioMenuButton extends StatelessWidget {
  final Player player;
  final VoidCallback onChanged;
  const SubtitleAudioMenuButton({super.key, required this.player, required this.onChanged});

  Future<void> _open(BuildContext context) async {
    final anchor = playerMenuAnchor(context);
    bool? subtitles;
    await showPlayerMenu(
      context, anchor: anchor, title: 'Audio & subtitles',
      actions: [
        PlayerMenuAction(
          label: 'Subtitles · ${player.state.track.subtitle.id == 'no' ? 'Off' : player.state.track.subtitle.language ?? 'Auto'}',
          icon: const Icon(LucideIcons.typeOutline), onPressed: () => subtitles = true),
        PlayerMenuAction(
          label: 'Audio · ${player.state.track.audio.language ?? 'Auto'}',
          icon: const Icon(LucideIcons.volume2), onPressed: () => subtitles = false),
      ],
    );
    if (!context.mounted || subtitles == null) return;
    if (subtitles!) {
      SubtitleTrack? selected;
      final current = player.state.track.subtitle.id;
      await showPlayerMenu(
        context, anchor: anchor, title: 'Subtitles',
        actions: [
          PlayerMenuAction(label: 'Off',
            icon: current == 'no' ? const Icon(LucideIcons.check) : null,
            onPressed: () => selected = SubtitleTrack.no()),
          for (final track in player.state.tracks.subtitle.where((t) => t.id != 'auto' && t.id != 'no'))
            PlayerMenuAction(label: track.title ?? track.language ?? track.id,
              icon: current == track.id ? const Icon(LucideIcons.check) : null,
              onPressed: () => selected = track),
        ],
      );
      final track = selected;
      if (!context.mounted || track == null) return;
      await PlaybackPreferences.instance.update(subtitle: track.language, enabled: track.id != 'no');
      await player.setSubtitleTrack(track);
    } else {
      AudioTrack? selected;
      final current = player.state.track.audio.id;
      await showPlayerMenu(
        context, anchor: anchor, title: 'Audio track',
        actions: [
          PlayerMenuAction(label: 'Automatic',
            icon: current == 'auto' ? const Icon(LucideIcons.check) : null,
            onPressed: () => selected = AudioTrack.auto()),
          for (final track in player.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no'))
            PlayerMenuAction(label: track.title ?? track.language ?? track.id,
              icon: current == track.id ? const Icon(LucideIcons.check) : null,
              onPressed: () => selected = track),
        ],
      );
      final track = selected;
      if (!context.mounted || track == null) return;
      await PlaybackPreferences.instance.update(audio: track.language);
      await player.setAudioTrack(track);
    }
    if (context.mounted) onChanged();
  }

  @override
  Widget build(BuildContext context) => ControlButton(
    onTap: () => _open(context),
    icon: Icon(LucideIcons.typeOutline, size: AppTypography.normalIconSize),
  );
}
