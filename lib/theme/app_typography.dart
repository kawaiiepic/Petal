import 'package:shadcn_flutter/shadcn_flutter_experimental.dart';
import 'package:sizer/sizer.dart';

abstract final class AppTypography {
  static double get labelSize =>
      Device.screenType == ScreenType.desktop ? 10.sp.clamp(10, 14) : 13.sp;

  static double get bodySize =>
      Device.screenType == ScreenType.desktop ? 12.sp.clamp(12, 16) : 14.sp;

  static double get smallSize =>
      Device.screenType == ScreenType.desktop ? 11.sp.clamp(11, 15) : 13.sp;

  static double get h3Size =>
      Device.screenType == ScreenType.desktop ? 15.sp.clamp(15, 20) : 20.sp;

  static double get h4Size =>
      Device.screenType == ScreenType.desktop ? 13.sp.clamp(13, 17) : 17.sp;

  static double get normalIconSize => 15.px.clamp(14, 20).toDouble();

  static TextStyle get normalTextStyle =>
      TextStyle(fontSize: 14.sp.clamp(12, 20));
}
