import 'package:petal/api/playback_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:petal/pages/player/overlay/player_dropdown_button.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SubtitleAudioMenuButton extends StatelessWidget {
  final Player player;
  final VoidCallback onChanged;

  const SubtitleAudioMenuButton({
    super.key,
    required this.player,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerDropdownButton(
      dropdownMenu: DropdownMenu(
        children: [
          MenuLabel(
            child: Row(
              children: [
                Icon(
                  size: AppTypography.normalIconSize,
                  LucideIcons.typeOutline,
                ),
                Text(style: AppTypography.normalTextStyle, 'Subtitles'),
                const Spacer(),
                ControlButton(
                  icon: Icon(
                    size: AppTypography.normalIconSize,
                    LucideIcons.upload,
                  ),
                ),
              ],
            ),
          ),
          const MenuDivider(),
          MenuButton(
            child: const Text('Subtitles off'),
            onPressed: (_) {
              PlaybackPreferences.instance.update(enabled: false);
              player.setSubtitleTrack(SubtitleTrack.no());
              onChanged();
            },
          ),
          MenuLabel(
            child: Collapsible(
              children: [
                CollapsibleTrigger(
                  child: Text(
                    style: AppTypography.normalTextStyle,
                    'Subtitles',
                  ),
                ),
                Text(
                  style: AppTypography.normalTextStyle,
                  player.state.track.subtitle.language ?? 'None',
                ).withPadding(left: 30),
                ...player.state.tracks.subtitle
                    .where((a) => a.id != "auto" && a.id != "no")
                    .map(
                      (e) => CollapsibleContent(
                        child: MenuButton(
                          onPressed: (context) {
                            PlaybackPreferences.instance.update(
                              subtitle: e.language,
                              enabled: true,
                            );
                            player.setSubtitleTrack(e);
                            onChanged();
                          },
                          child: Text(
                            style: AppTypography.normalTextStyle,
                            e.title ?? e.language ?? e.id,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          MenuLabel(
            child: Collapsible(
              children: [
                CollapsibleTrigger(
                  child: Text(
                    style: AppTypography.normalTextStyle,
                    'Audio Track',
                  ),
                ),
                Text(
                  style: AppTypography.normalTextStyle,
                  player.state.track.audio.language ?? 'None',
                ).withPadding(left: 30),
                ...player.state.tracks.audio
                    .where((a) => a.id != "auto" && a.id != "no")
                    .map(
                      (e) => CollapsibleContent(
                        child: MenuButton(
                          onPressed: (context) {
                            PlaybackPreferences.instance.update(
                              audio: e.language,
                            );
                            player.setAudioTrack(e);
                            onChanged();
                          },
                          child: Text(
                            style: AppTypography.normalTextStyle,
                            e.title ?? e.language ?? e.id,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      icon: Icon(size: AppTypography.normalIconSize, LucideIcons.typeOutline),
    );
  }
}
