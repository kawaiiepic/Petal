import 'package:petal/models/addon.dart';
import 'package:petal/models/downloads/download_entry.dart';

class StreamItem {
  final String name;
  final String title;
  final String url;
  final bool external;
  final Addon addon;
  final DownloadEntry? download;
  bool get isLocal => Uri.tryParse(url)?.scheme == 'file';

  // Optional parsed fields
  final int? season;
  final int? episode;

  StreamItem({
    required this.name,
    required this.title,
    required this.url,
    required this.external,
    required this.addon,
    this.season,
    this.episode,
    this.download,
  });

  factory StreamItem.localFile({
    required String path,
    required String title,
    DownloadEntry? download,
  }) => StreamItem(
    name: title,
    title: title,
    url: Uri.file(path).toString(),
    external: false,
    addon: Addon(
      id: 'local',
      userId: '',
      manifestUrl: '',
      baseUrl: '',
      forced: 0,
    ),
    download: download,
  );

  factory StreamItem.fromJson(Map<String, dynamic> json, Addon addon) {
    final name = json['name'] ?? '';
    final title = json['title'] ?? json['description'] ?? '';
    final url = json['url'] ?? json['externalUrl'] ?? '';
    final external = json['externalUrl'] != null;

    int? season;
    int? episode;

    // Try to extract S01E02 pattern from name
    final regex = RegExp(r'[Ss](\d{1,2})[Ee](\d{1,2})');
    final match = regex.firstMatch(title);

    if (match != null) {
      season = int.tryParse(match.group(1)!);
      episode = int.tryParse(match.group(2)!);
    }

    return StreamItem(
      name: name,
      title: title,
      url: url,
      external: external,
      addon: addon,
      season: season,
      episode: episode,
    );
  }
}
