import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

/// A URL-addressable popup that preserves the route underneath it.
class PopupPage extends material.Page<void> {
  final String title;
  final Widget child;
  final double maxWidth;

  const PopupPage({
    required super.key,
    required this.title,
    required this.child,
    this.maxWidth = 1000,
  });

  @override
  material.Route<void> createRoute(BuildContext context) =>
      material.RawDialogRoute<void>(
        settings: this,
        barrierDismissible: true,
        barrierLabel: 'Close $title',
        barrierColor: const Color(0x99000000),
        pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape):
                  () => Navigator.of(context).pop(),
            },
            child: Focus(
              autofocus: true,
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 8 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 900),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.background,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(title,
                                    style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Semantics(
                                    label: 'Close $title',
                                    button: true,
                                    child: IconButton.ghost(
                                      icon: const Icon(LucideIcons.x),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: child),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
