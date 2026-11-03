import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Video controls and their overlays need contrast regardless of the app theme.
class PlayerTheme extends StatelessWidget {
  final Widget child;

  const PlayerTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: () => ColorSchemes.darkGray.pink,
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: IconTheme.merge(
        data: const IconThemeData(color: Colors.white),
        child: child,
      ),
    ),
  );
}
