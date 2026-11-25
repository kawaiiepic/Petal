import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// An inset, theme-aware surface shared by Home and library screens.
class LibraryPanel extends StatelessWidget {
  const LibraryPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: .85),
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
