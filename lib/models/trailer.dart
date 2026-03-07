class Trailer {
  final String title;
  final String ytId;

  const Trailer({required this.title, required this.ytId});

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(title: json['title'] ?? '', ytId: json['ytId'] ?? '');
  }
}
