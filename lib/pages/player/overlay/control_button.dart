import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final bool filled;
  final double padding;
  const ControlButton({super.key, required this.icon, this.onTap, this.filled = false, this.padding = 8});

  @override
  Widget build(BuildContext context) =>
      glass.GlassButton.custom(
        onTap: onTap ?? () {}, enabled: onTap != null,
        useOwnLayer: true,
        style: filled ? glass.GlassButtonStyle.filled : glass.GlassButtonStyle.transparent,
        shape: const glass.LiquidRoundedRectangle(borderRadius: 32),
        child: Padding(padding: EdgeInsets.all(padding), child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: icon,
          ),
        )),
      );
}
