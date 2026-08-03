import 'package:sizer/sizer.dart';

abstract final class Misc {
  static String fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (h > 0) {
      return '$h:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }

  static double get labelSize => Device.screenType == ScreenType.desktop ? 10.sp : 13.sp;
  static double get bodySize => Device.screenType == ScreenType.desktop ? 12.sp : 14.sp;
  static double get smallSize => Device.screenType == ScreenType.desktop ? 11.sp : 13.sp;
  static double get h3Size => Device.screenType == ScreenType.desktop ? 15.sp : 20.sp;
  static double get h4Size => Device.screenType == ScreenType.desktop ? 13.sp : 17.sp;

  static String formatRuntime(int? minutes) {
    if (minutes == null) return '';
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  static String formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
