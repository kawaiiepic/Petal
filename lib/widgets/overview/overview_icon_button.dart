import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OverviewIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const OverviewIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return glass.GlassButton.custom(
      onTap: onTap, width: 40, height: 40, useOwnLayer: true,
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
