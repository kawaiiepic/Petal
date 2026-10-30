class Ids {
  String slug;

  Ids({required this.slug});

  factory Ids.fromJson(Map<String, dynamic> json) => Ids(slug: json["slug"]);

  Map<String, dynamic> toJson() => {"slug": slug};
}
