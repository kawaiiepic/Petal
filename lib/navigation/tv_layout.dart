import 'package:flutter/widgets.dart';
import 'package:sizer/sizer.dart';

/// Sizer compares the short side in landscape and the width in portrait.
const tvTabletBreakpoint = 739.0;
const tvDesktopSidebarWidth = 206.0;

/// Propagates Sizer's screen type to routing and widgets when the window resizes.
class TvLayout extends InheritedWidget {
  const TvLayout({super.key, required this.screenType, required super.child});

  final ScreenType screenType;

  static ScreenType of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TvLayout>()?.screenType ??
      Device.screenType;

  static bool isCompact(BuildContext context) =>
      of(context) != ScreenType.desktop;

  @override
  bool updateShouldNotify(TvLayout oldWidget) =>
      screenType != oldWidget.screenType;
}
