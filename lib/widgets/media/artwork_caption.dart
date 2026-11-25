import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A readable bottom caption that fades into the artwork above it.
class ArtworkCaption extends StatelessWidget {
  const ArtworkCaption({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0xA6000000), Color(0xEB000000)],
        stops: [0, .49, 1],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 23, 10, 10),
      child: child,
    ),
  );
}
