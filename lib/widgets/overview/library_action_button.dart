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
    return Button(
      onPressed: busy ? null : onTap,
      style:
          (active ? const ButtonStyle.primary() : const ButtonStyle.outline())
              .withBorderRadius(
                borderRadius: BorderRadius.circular(16),
                hoverBorderRadius: BorderRadius.circular(16),
              ),
      child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
        Icon(icon, size: 18),
        if (busy) const CircularProgressIndicator(size: 14),
      ]),
    );
  }
}
