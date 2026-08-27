enum MediaType { movie, show, season, episode, person, user }

extension MediaTypeExtension on MediaType {
  String get toTmdbSafe {
    switch (this) {
      case MediaType.movie:
        return "series";
      case MediaType.show:
        return "movie";
      default:
        return "";
    }
  }

  MediaType fromTmdbSafe(String tmdbString) {
    switch (tmdbString) {
      case "movie":
        return MediaType.movie;
      case "series":
        return MediaType.show;
      default:
        return MediaType.show;
    }
  }
}
