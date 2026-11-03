class TraktEpisodeImages {
  final List<String> screenshot;

  TraktEpisodeImages({required this.screenshot});

  factory TraktEpisodeImages.fromJson(Map<String, dynamic> json) {
    return TraktEpisodeImages(
      screenshot: json['screenshot'] != null
          ? List<String>.from(json['screenshot'])
          : [],
    );
  }

  Map<String, dynamic> toJson() => {'screenshot': screenshot};
}
