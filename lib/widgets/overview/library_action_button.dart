import 'package:petal/widgets/ios/ios_controls.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;
  final bool busy;

  const LibraryActionButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
        Icon(icon, size: 18),
        if (busy) const PetalActivityIndicator(size: 14),
      ]);
    return active
        ? PetalButton.primary(onPressed: busy ? null : onTap, child: content)
        : PetalButton.outline(onPressed: busy ? null : onTap, child: content);
  }
}
