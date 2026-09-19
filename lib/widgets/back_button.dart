import 'package:go_router/go_router.dart';
import 'package:petal/main.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: OutlineButton(
        density: ButtonDensity.icon,
        onPressed: () => PetalApp.rootNavigatorKey.currentContext?.pop(),
        child: const Icon(LucideIcons.chevronLeft),
      ),
    );
  }
}
