class Settings {
  final bool traktConnected;

  Settings({required this.traktConnected});

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(traktConnected: json['traktConnected'] ?? false);
  }
}
