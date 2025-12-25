import 'package:blssmpetal/models/addon.dart';

class StreamItem {
  final String name;
  final String title;
  final String? url;
  final Addon addon;

  StreamItem({required this.name, required this.title, required this.url, required this.addon});

  factory StreamItem.fromJson(Map<String, dynamic> json, Addon addon) {
    return StreamItem(name: json['name'] ?? '', title: json['title'] ?? addon.name, url: json['url'], addon: addon);
  }
}
