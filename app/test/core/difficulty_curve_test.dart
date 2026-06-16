import 'package:alaif/core/difficulty_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stageFor returns Calm below 300', () {
    expect(stageFor(0).name, 'Calm');
    expect(stageFor(299).name, 'Calm');
  });

  test('stageFor returns Brisk in 300..899', () {
    expect(stageFor(300).name, 'Brisk');
    expect(stageFor(899).name, 'Brisk');
  });

  test('stageFor returns Frenzy at 900+', () {
    expect(stageFor(900).name, 'Frenzy');
    expect(stageFor(99999).name, 'Frenzy');
  });

  test('Calm baseline params match spec', () {
    final s = kCalm;
    expect(s.baselineInterval, 1.10);
    expect(s.batchMin, 1);
    expect(s.batchMax, 1);
    expect(s.letterSpeed, 1.00);
    expect(s.bombChance, 0.05);
  });

  test('Frenzy baseline params match spec', () {
    final s = kFrenzy;
    expect(s.baselineInterval, 0.55);
    expect(s.batchMin, 2);
    expect(s.batchMax, 3);
    expect(s.letterSpeed, 1.30);
    expect(s.bombChance, 0.20);
  });

  test('surge weights sum to 1.0 for every stage', () {
    for (final s in [kCalm, kBrisk, kFrenzy]) {
      final sum = s.surgeLetterWeight + s.surgeBombWeight + s.surgeBothWeight;
      expect(sum, closeTo(1.0, 1e-9), reason: s.name);
    }
  });

  test('Brisk surge params match spec', () {
    expect(kBrisk.surgeCadence, 10.0);
    expect(kBrisk.surgeCount, 5);
    expect(kBrisk.surgeLetterWeight, 0.55);
    expect(kBrisk.surgeBombWeight, 0.25);
    expect(kBrisk.surgeBothWeight, 0.20);
  });
}
