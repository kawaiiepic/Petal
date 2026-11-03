enum MediaType { movie, show, season, episode, person, user }

extension MediaTypeExtension on MediaType {
  String get toTmdbSafe {
    switch (this) {
      case MediaType.movie:
        return "movie";
      case MediaType.show:
        return "series";
      default:
        return "";
    }
  }

  String get toBackendSafe {
    switch (this) {
      case MediaType.movie:
        return "movie";
      case MediaType.show:
        return "episode";
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
