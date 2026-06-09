import 'package:alaif/core/difficulty_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curve = DifficultyCurve();

  test('spawn interval starts high and decreases', () {
    expect(curve.spawnInterval(0), DifficultyCurve.startInterval);
    expect(curve.spawnInterval(30), lessThan(curve.spawnInterval(0)));
  });

  test('spawn interval floors at minInterval', () {
    expect(curve.spawnInterval(9999), DifficultyCurve.minInterval);
  });

  test('bomb chance starts low and rises', () {
    expect(curve.bombChance(0), DifficultyCurve.startBombChance);
    expect(curve.bombChance(30), greaterThan(curve.bombChance(0)));
  });

  test('bomb chance caps at maxBombChance', () {
    expect(curve.bombChance(9999), DifficultyCurve.maxBombChance);
  });
}
