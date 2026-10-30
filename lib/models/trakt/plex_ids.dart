class PlexIds {
  final String guid;

  PlexIds({required this.guid});

  factory PlexIds.fromJson(Map<String, dynamic> json) =>
      PlexIds(guid: json['guid'] as String);

  Map<String, dynamic> toJson() => {'guid': guid};
}
