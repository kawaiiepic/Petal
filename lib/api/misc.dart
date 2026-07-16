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
}
