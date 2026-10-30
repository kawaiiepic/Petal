import 'package:petal/models/media_type.dart';

class ShelfItem {
  final int tmdbId;
  final MediaType type;
  final String? subtitle;

  const ShelfItem({required this.tmdbId, required this.type, this.subtitle});
}
