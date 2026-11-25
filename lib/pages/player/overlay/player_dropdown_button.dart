import 'package:petal/pages/player/overlay/control_button.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class PlayerDropdownButton extends StatelessWidget {
  final Widget icon;
  final DropdownMenu dropdownMenu;
  const PlayerDropdownButton({
    super.key,
    required this.icon,
    required this.dropdownMenu,
  });

  @override
  Widget build(BuildContext context) => ControlButton(
    onTap: () {
      showDropdown(
        context: context,
        consumeOutsideTaps: true,
        alignment: Alignment.topCenter,
        builder: (context) => dropdownMenu,
      );
    },
    icon: icon,
  );
}
