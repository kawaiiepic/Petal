import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OverviewIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const OverviewIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton.ghost(
      onPressed: onTap,
      shape: ButtonShape.circle,
      density: ButtonDensity.icon,
      icon: Icon(icon, color: Colors.pink),
    );
  }
}
