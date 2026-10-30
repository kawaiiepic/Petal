class TraktSeasonImages {
  final List<String> thumb;
  final List<String> poster;

  TraktSeasonImages({required this.thumb, required this.poster});

  factory TraktSeasonImages.fromJson(Map<String, dynamic> json) {
    return TraktSeasonImages(
      thumb: json['thumb'] != null ? List<String>.from(json['thumb']) : [],
      poster: json['poster'] != null ? List<String>.from(json['poster']) : [],
    );
  }

  Map<String, dynamic> toJson() => {'thumb': thumb, 'poster': poster};
}
