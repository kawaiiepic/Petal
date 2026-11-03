class TraktTimestampActivity {
  final DateTime updatedAt;

  TraktTimestampActivity({required this.updatedAt});

  factory TraktTimestampActivity.fromJson(Map<String, dynamic> json) =>
      TraktTimestampActivity(updatedAt: DateTime.parse(json['updated_at']));
}
