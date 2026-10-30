import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

class LibraryActionButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const LibraryActionButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style:
          (active ? const ButtonStyle.primary() : const ButtonStyle.outline())
              .withBorderRadius(
                borderRadius: BorderRadius.circular(16),
                hoverBorderRadius: BorderRadius.circular(16),
              ),
      child: Icon(icon, size: 18),
    );
  }
}
