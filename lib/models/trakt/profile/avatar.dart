class Avatar {
  String full;

  Avatar({required this.full});

  factory Avatar.fromJson(Map<String, dynamic> json) =>
      Avatar(full: json["full"]);

  Map<String, dynamic> toJson() => {"full": full};
}
