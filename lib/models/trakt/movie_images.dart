class MovieImages {
  final List<String>? logo;
  final List<String>? poster;
  final List<String>? banner;
  final List<String>? fanart;
  final List<String>? thumb;
  final List<String>? clearart;

  MovieImages({
    this.logo,
    this.poster,
    this.banner,
    this.fanart,
    this.thumb,
    this.clearart,
  });

  factory MovieImages.fromJson(Map<String, dynamic> json) {
    return MovieImages(
      logo: json['logo'] != null ? List<String>.from(json['logo']) : null,
      poster: json['poster'] != null ? List<String>.from(json['poster']) : null,
      banner: json['banner'] != null ? List<String>.from(json['banner']) : null,
      fanart: json['fanart'] != null ? List<String>.from(json['fanart']) : null,
      thumb: json['thumb'] != null ? List<String>.from(json['thumb']) : null,
      clearart: json['clearart'] != null
          ? List<String>.from(json['clearart'])
          : null,
    );
  }
}
