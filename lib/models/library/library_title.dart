import 'package:petal/models/library/title_rating.dart';
import 'package:petal/models/media_type.dart';

class LibraryTitle {
  final int tmdbId;
  final MediaType type;
  final TitleRating rating;
  final bool watchlisted;

  const LibraryTitle({
    required this.tmdbId,
    required this.type,
    this.rating = TitleRating.none,
    this.watchlisted = false,
  });
}
