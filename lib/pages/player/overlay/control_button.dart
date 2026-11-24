import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const ControlButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) =>
      glass.GlassButton.custom(
        onTap: onTap ?? () {}, enabled: onTap != null,
        useOwnLayer: true, style: glass.GlassButtonStyle.transparent,
        child: Padding(padding: const EdgeInsets.all(8), child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: icon,
          ),
        )),
      );
}
