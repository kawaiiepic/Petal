DateTime? dateFromUnix(num? raw) {
  final value = raw?.toInt();
  if (value == null || value == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(value * 1000);
}

List<DateTime> watchDatesFrom(dynamic raw, DateTime? fallback) {
  final out = <DateTime>[];
  if (raw is List) {
    for (final item in raw) {
      final date = dateFromUnix(item as num?);
      if (date != null) out.add(date);
    }
  }
  if (out.isEmpty && fallback != null) out.add(fallback);
  return out;
}

/// Backend last_watched may be a Unix timestamp or an ISO date.
DateTime? lastWatchedFrom(dynamic raw) {
  if (raw is String) {
    final number = num.tryParse(raw);
    return number == null ? DateTime.tryParse(raw) : lastWatchedFrom(number);
  }
  if (raw is! num || raw <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    (raw < 100000000000 ? raw * 1000 : raw).toInt(),
    isUtc: true,
  );
}
