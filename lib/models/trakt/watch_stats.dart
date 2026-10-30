class WatchStats {
  final int? playCount;
  final int? minutesWatched;
  final int? minutesLeft;

  WatchStats({this.playCount, this.minutesWatched, this.minutesLeft});

  factory WatchStats.fromJson(Map<String, dynamic> json) {
    return WatchStats(
      playCount: json['play_count'] as int?,
      minutesWatched: json['minutes_watched'] as int?,
      minutesLeft: json['minutes_left'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (playCount != null) 'play_count': playCount,
    if (minutesWatched != null) 'minutes_watched': minutesWatched,
    if (minutesLeft != null) 'minutes_left': minutesLeft,
  };
}
