import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' as ios;
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

bool get usesPetalIosNavigation =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class IosNavigationDock extends StatelessWidget {
  const IosNavigationDock({
    super.key,
    required this.onHome,
    required this.onCollection,
    required this.onHistory,
    required this.onDownloads,
  });

  // Leave enough trailing scroll space for content behind the floating dock.
  static const clearance = 82.0;

  final VoidCallback onHome;
  final VoidCallback onCollection;
  final VoidCallback onHistory;
  final VoidCallback onDownloads;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(28);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.card.withValues(alpha: dark ? .78 : .86),
              borderRadius: radius,
              border: Border.all(
                color: scheme.foreground.withValues(alpha: .13),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Row(
                children: [
                  _DockItem(
                    ios.CupertinoIcons.house_fill,
                    'Home',
                    onHome,
                    selected: true,
                  ),
                  _DockItem(
                    ios.CupertinoIcons.square_stack,
                    'Collection',
                    onCollection,
                  ),
                  _DockItem(ios.CupertinoIcons.clock, 'History', onHistory),
                  _DockItem(
                    ios.CupertinoIcons.arrow_down_circle,
                    'Downloads',
                    onDownloads,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem(
    this.icon,
    this.label,
    this.onPressed, {
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.foreground;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: ios.CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: selected ? color.withValues(alpha: .13) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
