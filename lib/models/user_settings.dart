class UserSettings {
  final bool traktConnected;

  UserSettings({required this.traktConnected});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(traktConnected: json['traktConnected'] ?? false);
  }
}
