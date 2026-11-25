import 'package:petal/pages/player/overlay/player_glass_panel.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:petal/widgets/settings/playback_preferences_card.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PlayerSettingsMenuButton extends StatelessWidget {
  final Player player;
  const PlayerSettingsMenuButton({super.key, required this.player});

  Future<void> _open(BuildContext context) async {
    String? selection;
    await glass.showGlassActionSheet<void>(
      context: context, title: 'Playback settings',
      actions: [
        glass.GlassActionSheetAction(label: 'Playback preferences',
          icon: const Icon(LucideIcons.settings2), onPressed: () => selection = 'preferences'),
        glass.GlassActionSheetAction(label: 'Keyboard shortcuts',
          icon: const Icon(LucideIcons.info), onPressed: () => selection = 'shortcuts'),
        glass.GlassActionSheetAction(label: 'Take screenshot',
          icon: const Icon(LucideIcons.camera), onPressed: () => selection = 'screenshot'),
      ],
    );
    if (!context.mounted) return;
    if (selection == 'preferences') {
      await showPlayerGlassPanel<void>(context, title: 'Playback preferences',
        builder: (_) => const PlaybackPreferencesCard());
    } else if (selection == 'shortcuts') {
      await showPlayerGlassPanel<void>(context, title: 'Keyboard shortcuts',
        builder: (_) => const Column(crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12, children: [
            Text('Space / K   Play or pause'),
            Text('← / → or J / L   Seek 10 seconds'),
            Text('↑ / ↓   Volume · M   Mute'),
            Text('S   Subtitles · F   Fullscreen · Esc   Exit'),
            Text('+ / −   Playback speed'),
            Text('[ / ]   Subtitle delay'),
          ]));
    } else if (selection == 'screenshot') {
      await player.screenshot();
    }
  }

  @override
  Widget build(BuildContext context) => ControlButton(
    onTap: () => _open(context),
    icon: Icon(LucideIcons.settings2, size: AppTypography.normalIconSize),
  );
}
