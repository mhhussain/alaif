import 'package:alaif/core/score_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatScore groups thousands with commas', () {
    expect(formatScore(0), '0');
    expect(formatScore(7), '7');
    expect(formatScore(999), '999');
    expect(formatScore(8640), '8,640');
    expect(formatScore(14820), '14,820');
    expect(formatScore(1234567), '1,234,567');
  });
}
