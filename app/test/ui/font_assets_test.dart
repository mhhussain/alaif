import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontFiles = [
    'assets/fonts/Spectral-Regular.ttf',
    'assets/fonts/Spectral-Italic.ttf',
    'assets/fonts/Spectral-Medium.ttf',
    'assets/fonts/Spectral-MediumItalic.ttf',
    'assets/fonts/Katibeh-Regular.ttf',
    'assets/fonts/OFL-Spectral.txt',
    'assets/fonts/OFL-Katibeh.txt',
  ];

  test('all vendored font files and licenses exist and are non-empty', () {
    for (final path in fontFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(file.lengthSync(), greaterThan(0), reason: '$path is empty');
    }
  });

  test('ArefRuqaa font files are no longer vendored', () {
    for (final path in [
      'assets/fonts/ArefRuqaa-Regular.ttf',
      'assets/fonts/ArefRuqaa-Bold.ttf',
      'assets/fonts/OFL-ArefRuqaa.txt',
    ]) {
      expect(File(path).existsSync(), isFalse,
          reason: '$path should have been removed with the Katibeh swap');
    }
  });

  test('pubspec declares both font families and the Katibeh asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Spectral'));
    expect(pubspec, contains('family: Katibeh'));
    expect(pubspec, contains('assets/fonts/Spectral-MediumItalic.ttf'));
    expect(pubspec, contains('assets/fonts/Katibeh-Regular.ttf'));
    expect(pubspec, isNot(contains('ArefRuqaa')));
  });
}
