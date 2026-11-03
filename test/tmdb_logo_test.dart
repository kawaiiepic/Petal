import 'package:flutter_test/flutter_test.dart';
import 'package:petal/models/tmdb/tmdb_images.dart';

void main() {
  test('logo selection prefers English, then neutral, without changing source order', () {
    final images = TmdbImages.fromJson({
      'logos': [
        {'file_path': '/french.png', 'iso_639_1': 'fr', 'vote_average': 10},
        {'file_path': '/neutral.png', 'iso_639_1': null, 'vote_average': 9},
        {'file_path': '/english.png', 'iso_639_1': 'en', 'vote_average': 5},
      ],
    });
    expect(images.preferredLogo!.filePath, '/english.png');
    expect(images.logos.first.filePath, '/french.png');
    images.logos.removeLast();
    expect(images.preferredLogo!.filePath, '/neutral.png');
  });

  test('empty paths are ignored and ties use resolution', () {
    final images = TmdbImages.fromJson({
      'logos': [
        {'file_path': '', 'iso_639_1': 'en', 'vote_average': 10},
        {'file_path': '/small.png', 'iso_639_1': 'en', 'width': 100},
        {'file_path': '/large.png', 'iso_639_1': 'en', 'width': 500},
      ],
    });
    expect(images.preferredLogo!.filePath, '/large.png');
    expect(TmdbImages.fromJson({}).preferredLogo, isNull);
  });
}
