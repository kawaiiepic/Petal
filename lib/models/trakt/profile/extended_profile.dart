import 'dart:convert';

ExtendedProfile profileFromJson(String str) => ExtendedProfile.fromJson(json.decode(str));
String profileToJson(ExtendedProfile data) => json.encode(data.toJson());

class ExtendedProfile {
  String username;
  bool private;
  String name;
  bool vip;
  bool vipEp;
  Ids ids;
  DateTime joinedAt;
  String location;
  String about;
  String gender;
  int age;
  Images images;

  ExtendedProfile({
    required this.username,
    required this.private,
    required this.name,
    required this.vip,
    required this.vipEp,
    required this.ids,
    required this.joinedAt,
    required this.location,
    required this.about,
    required this.gender,
    required this.age,
    required this.images,
  });

  factory ExtendedProfile.fromJson(Map<String, dynamic> json) => ExtendedProfile(
    username: json["username"],
    private: json["private"],
    name: json["name"],
    vip: json["vip"],
    vipEp: json["vip_ep"],
    ids: Ids.fromJson(json["ids"]),
    joinedAt: DateTime.parse(json["joined_at"]),
    location: json["location"],
    about: json["about"],
    gender: json["gender"],
    age: json["age"],
    images: Images.fromJson(json["images"]),
  );

  Map<String, dynamic> toJson() => {
    "username": username,
    "private": private,
    "name": name,
    "vip": vip,
    "vip_ep": vipEp,
    "ids": ids.toJson(),
    "joined_at": joinedAt.toIso8601String(),
    "location": location,
    "about": about,
    "gender": gender,
    "age": age,
    "images": images.toJson(),
  };
}

class Ids {
  String slug;

  Ids({required this.slug});

  factory Ids.fromJson(Map<String, dynamic> json) => Ids(slug: json["slug"]);

  Map<String, dynamic> toJson() => {"slug": slug};
}

class Images {
  Avatar avatar;

  Images({required this.avatar});

  factory Images.fromJson(Map<String, dynamic> json) => Images(avatar: Avatar.fromJson(json["avatar"]));

  Map<String, dynamic> toJson() => {"avatar": avatar.toJson()};
}

class Avatar {
  String full;

  Avatar({required this.full});

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(full: json["full"]);

  Map<String, dynamic> toJson() => {"full": full};
}
