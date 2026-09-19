import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const ControlButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) =>
      IconButton(variance: ButtonVariance.ghost, onPressed: onTap, icon: icon);
}

class PlayerDropdownButton extends StatelessWidget {
  final Widget icon;
  final DropdownMenu dropdownMenu;
  const PlayerDropdownButton({super.key, required this.icon, required this.dropdownMenu});

  @override
  Widget build(BuildContext context) => IconButton(
        variance: ButtonVariance.ghost,
        onPressed: () {
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
