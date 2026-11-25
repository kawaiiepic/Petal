class PersonSearchResult {
  const PersonSearchResult({required this.id, required this.name,
    required this.profilePath, required this.knownFor});
  final int id;
  final String name;
  final String? profilePath;
  final String knownFor;

  factory PersonSearchResult.fromJson(Map<String, dynamic> json) {
    final titles = (json['known_for'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => entry['title'] ?? entry['name'])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(2).join(' · ');
    final profile = json['profile_path'];
    return PersonSearchResult(id: json['id'] as int, name: json['name'] as String,
      profilePath: profile is String && profile.isNotEmpty ? profile : null,
      knownFor: titles.isEmpty ? 'Actor' : titles);
  }
}
