import 'package:petal/models/trakt/profile/avatar.dart';

class Images {
  Avatar avatar;

  Images({required this.avatar});

  factory Images.fromJson(Map<String, dynamic> json) =>
      Images(avatar: Avatar.fromJson(json["avatar"]));

  Map<String, dynamic> toJson() => {"avatar": avatar.toJson()};
}
