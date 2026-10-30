class Network {
  final int id;
  final String name;
  final String? logoPath;
  final String originCountry;

  static const _imageBase = 'https://image.tmdb.org/t/p/w185';

  Network({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.originCountry,
  });

  String? get logoUrl => logoPath != null ? '$_imageBase$logoPath' : null;

  factory Network.fromJson(Map<String, dynamic> json) => Network(
    id: json['id'],
    name: json['name'] ?? '',
    logoPath: json['logo_path'],
    originCountry: json['origin_country'] ?? '',
  );
}
