import 'package:blssmpetal/models/addon.dart';

class StreamItem {
  final String name;
  final String title;
  final String url;
  final Addon addon;

  // Optional parsed fields
  final int? season;
  final int? episode;

  StreamItem({required this.name, required this.title, required this.url, required this.addon, this.season, this.episode});

  factory StreamItem.fromJson(Map<String, dynamic> json, Addon addon) {
    final name = json['name'] ?? '';
    final title = json['title'] ?? json['description'] ?? '';
    final url = json['url'] ?? '';

    int? season;
    int? episode;

    // Try to extract S01E02 pattern from name
    final regex = RegExp(r'[Ss](\d{1,2})[Ee](\d{1,2})');
    final match = regex.firstMatch(title);

    print(title);

    if (match != null) {
      print("First Match ${match.group(1)} Second Match ${match.group(2)}");

      season = int.tryParse(match.group(1)!);
      episode = int.tryParse(match.group(2)!);
    }

    return StreamItem(name: name, title: title, url: url, addon: addon, season: season, episode: episode);
  }
}
