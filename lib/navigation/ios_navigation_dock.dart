import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as ios;
import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';

enum DockDestination {
  home('/', 'Home', ios.CupertinoIcons.house_fill),
  collection('/collection', 'Collection', ios.CupertinoIcons.square_stack),
  history('/history', 'History', ios.CupertinoIcons.clock),
  downloads('/downloads', 'Downloads', ios.CupertinoIcons.arrow_down_circle),
  search('/search', 'Search', ios.CupertinoIcons.search);

  const DockDestination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}

class IosNavigationDock extends StatelessWidget {
  const IosNavigationDock({
    super.key,
    required this.selectedDestination,
    required this.onSelected,
  });

  // Leave enough space for content above the floating dock.
  static const clearance = 82.0;

  final DockDestination selectedDestination;
  final ValueChanged<DockDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const selected = Color(0xFF2D91FF);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: glass.GlassTabBar.bottom(
        tabs: [
          for (final destination in DockDestination.values)
            glass.GlassTab(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
        selectedIndex: selectedDestination.index,
        onTabSelected: (index) => onSelected(DockDestination.values[index]),
        barHeight: 60,
        iconSize: 21,
        horizontalPadding: 0,
        verticalPadding: 0,
        selectedIconColor: selected,
        selectedLabelColor: selected,
        unselectedIconColor: scheme.foreground,
        unselectedLabelColor: scheme.foreground,
        indicatorColor: selected.withValues(alpha: .15),
      ),
    );
  }
}
