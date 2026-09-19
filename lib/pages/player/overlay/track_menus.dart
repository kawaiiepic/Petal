import 'dart:typed_data';

import 'package:media_kit/media_kit.dart';
import 'package:petal/api/misc.dart';
import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class SubtitleAudioMenuButton extends StatelessWidget {
  final Player player;
  final VoidCallback onChanged;

  const SubtitleAudioMenuButton({super.key, required this.player, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PlayerDropdownButton(
      dropdownMenu: DropdownMenu(
        children: [
          MenuLabel(
            child: Row(
              children: [
                Icon(size: Misc.normalIconSize, LucideIcons.typeOutline),
                Text(style: Misc.normalTextStyle, 'Subtitles'),
                const Spacer(),
                ControlButton(icon: Icon(size: Misc.normalIconSize, LucideIcons.upload)),
              ],
            ),
          ),
          const MenuDivider(),
          MenuLabel(
            child: Collapsible(
              children: [
                CollapsibleTrigger(child: Text(style: Misc.normalTextStyle, 'Subtitles')),
                Text(style: Misc.normalTextStyle, player.state.track.subtitle.language ?? 'None').withPadding(left: 30),
                ...player.state.tracks.subtitle
                    .where((a) => a.id != "auto" && a.id != "no")
                    .map(
                      (e) => CollapsibleContent(
                        child: MenuButton(
                          onPressed: (context) {
                            player.setSubtitleTrack(e);
                            onChanged();
                          },
                          child: Text(style: Misc.normalTextStyle, e.title ?? e.language ?? e.id),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          MenuLabel(
            child: Collapsible(
              children: [
                CollapsibleTrigger(child: Text(style: Misc.normalTextStyle, 'Audio Track')),
                Text(style: Misc.normalTextStyle, player.state.track.audio.language ?? 'None').withPadding(left: 30),
                ...player.state.tracks.audio
                    .where((a) => a.id != "auto" && a.id != "no")
                    .map(
                      (e) => CollapsibleContent(
                        child: MenuButton(
                          onPressed: (context) {
                            player.setAudioTrack(e);
                            onChanged();
                          },
                          child: Text(style: Misc.normalTextStyle, e.title ?? e.language ?? e.id),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
      icon: Icon(size: Misc.normalIconSize, LucideIcons.typeOutline),
    );
  }
}

class PlayerSettingsMenuButton extends StatelessWidget {
  final Player player;

  const PlayerSettingsMenuButton({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return PlayerDropdownButton(
      dropdownMenu: DropdownMenu(
        children: [
          MenuLabel(
            child: Row(
              spacing: 8,
              children: [
                Icon(size: Misc.normalIconSize, LucideIcons.settings2),
                Text(style: Misc.normalTextStyle, 'Settings'),
              ],
            ),
          ),
          MenuDivider(),
          MenuButton(
            child: Text('Take Screenshot'),
            onPressed: (context) async {
              final Uint8List? screenshot = await player.screenshot();
              screenshot;
            },
          ),
        ],
      ),
      icon: Icon(size: Misc.normalIconSize, LucideIcons.settings2),
    );
  }
}
