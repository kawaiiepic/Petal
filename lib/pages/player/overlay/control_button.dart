// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  const ControlButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) =>
      ios.CupertinoButton(
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(32, 32),
        onPressed: onTap,
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: icon,
          ),
        ),
      );
}
