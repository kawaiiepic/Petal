import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;
// ignore: deprecated_member_use
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: glass.GlassTabBar.bottom(
        tabs: const [
          glass.GlassTab(icon: Icon(ios.CupertinoIcons.house_fill), label: 'Home'),
          glass.GlassTab(icon: Icon(ios.CupertinoIcons.square_stack), label: 'Collection'),
          glass.GlassTab(icon: Icon(ios.CupertinoIcons.clock), label: 'History'),
          glass.GlassTab(icon: Icon(ios.CupertinoIcons.arrow_down_circle), label: 'Downloads'),
        ],
        selectedIndex: 0,
        onTabSelected: (index) {
          switch (index) {
            case 0: onHome(); break;
            case 1: onCollection(); break;
            case 2: onHistory(); break;
            case 3: onDownloads(); break;
          }
        },
        barHeight: 60,
        iconSize: 21,
        horizontalPadding: 0,
        verticalPadding: 0,
        selectedIconColor: scheme.primary,
        selectedLabelColor: scheme.primary,
        unselectedIconColor: scheme.foreground,
        unselectedLabelColor: scheme.foreground,
        indicatorColor: scheme.primary.withValues(alpha: .16),
      ),
    );
  }
}
