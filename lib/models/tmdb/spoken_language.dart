class SpokenLanguage {
  final String englishName;
  final String iso639_1;
  final String name;

  SpokenLanguage({
    required this.englishName,
    required this.iso639_1,
    required this.name,
  });

  factory SpokenLanguage.fromJson(Map<String, dynamic> json) => SpokenLanguage(
    englishName: json['english_name'] ?? '',
    iso639_1: json['iso_639_1'] ?? '',
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'english_name': englishName,
    'iso_639_1': iso639_1,
    'name': name,
  };
}
