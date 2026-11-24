// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:petal/app/petal_app.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackButton extends StatelessWidget {
  const BackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ios.CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(40, 40),
      color: colors.card,
      borderRadius: BorderRadius.circular(100),
      onPressed: () {
        final ctx = PetalApp.rootNavigatorKey.currentContext ?? context;
        final nav = Navigator.of(ctx);
        if (nav.canPop()) nav.pop();
      },
      child: Icon(ios.CupertinoIcons.chevron_left, color: colors.foreground, size: 20),
    );
  }
}
