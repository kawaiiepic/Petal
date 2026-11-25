import 'package:petal/navigation/tv_layout.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// Library screens share the desktop shell's background instead of painting
/// their own opaque Scaffold. Compact screens keep the existing layout.
class LibraryPageFrame extends StatelessWidget {
  const LibraryPageFrame({super.key, required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (TvLayout.isCompact(context)) {
      return Scaffold(headers: [header], child: child);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, Expanded(child: child)],
    );
  }
}
