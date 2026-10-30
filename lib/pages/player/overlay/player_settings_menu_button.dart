import 'dart:typed_data';

import 'package:media_kit/media_kit.dart';
import 'package:petal/pages/player/overlay/player_dropdown_button.dart';
import 'package:petal/theme/app_typography.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

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
                Icon(size: AppTypography.normalIconSize, LucideIcons.settings2),
                Text(style: AppTypography.normalTextStyle, 'Settings'),
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
      icon: Icon(size: AppTypography.normalIconSize, LucideIcons.settings2),
    );
  }
}
