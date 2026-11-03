class EpisodeImages {
  final List<String> screenshot;

  EpisodeImages({required this.screenshot});

  factory EpisodeImages.fromJson(Map<String, dynamic> json) {
    return EpisodeImages(
      screenshot: List<String>.from(json['screenshot'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {'screenshot': screenshot};
}
