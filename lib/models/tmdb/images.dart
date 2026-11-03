import 'package:petal/models/tmdb/backdrops.dart';
import 'package:petal/models/tmdb/logos.dart';

class Images {
  List<Backdrops>? backdrops;
  int? id;
  List<Logos>? logos;
  List<Logos>? posters;
  List<Logos>? stills;

  Images({this.backdrops, this.id, this.logos, this.posters, this.stills});

  Images.fromJson(Map<String, dynamic> json) {
    // if (json['backdrops'] != null) {
    //   backdrops = <Backdrops>[];
    //   json['backdrops'].forEach((v) {
    //     backdrops!.add(Backdrops.fromJson(v));
    //   });
    // }
    // id = json['id'];
    // if (json['logos'] != null) {
    //   logos = <Logos>[];
    //   json['logos'].forEach((v) {
    //     logos!.add(Logos.fromJson(v));
    //   });
    // }
    // if (json['posters'] != null) {
    //   posters = <Logos>[];
    //   json['posters'].forEach((v) {
    //     posters!.add(Logos.fromJson(v));
    //   });
    // }
    if (json['stills'] != null) {
      stills = <Logos>[];
      json['stills'].forEach((v) {
        stills!.add(Logos.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (backdrops != null) {
      data['backdrops'] = backdrops!.map((v) => v.toJson()).toList();
    }
    data['id'] = id;
    if (logos != null) {
      data['logos'] = logos!.map((v) => v.toJson()).toList();
    }
    if (posters != null) {
      data['posters'] = posters!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
