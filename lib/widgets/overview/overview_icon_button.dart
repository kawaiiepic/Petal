// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class OverviewIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const OverviewIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ios.CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 40),
      borderRadius: BorderRadius.circular(100),
      color: Theme.of(context).colorScheme.secondary,
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}
