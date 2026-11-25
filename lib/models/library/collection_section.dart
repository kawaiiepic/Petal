enum CollectionSection {
  watching('Watching', 'Continue the titles you have started.'),
  watchlist('Watchlist', 'Titles you have saved for later.'),
  liked('Liked', 'Movies and shows you liked or loved.'),
  watched('Watched', 'Titles you have finished watching.'),
  planned('Planned', 'Titles in your history that you have not started.');

  const CollectionSection(this.label, this.description);
  final String label;
  final String description;
  String get route => '/collection?section=$name';

  static CollectionSection? parse(String? value) {
    for (final section in values) {
      if (section.name == value) return section;
    }
    return null;
  }
}
