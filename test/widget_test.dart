import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Material Icons font is not bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('uses-material-design: false'));
    expect(pubspec, isNot(contains('uses-material-design: true')));
  });
}
