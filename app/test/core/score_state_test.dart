import 'package:alaif/core/score_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each hit scores pointsPerLetter', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    expect(state.score, 2 * ScoreState.pointsPerLetter);
  });

  test('no combo bonus for fewer than 3 hits in a swipe', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    expect(state.score, 2 * ScoreState.pointsPerLetter);
  });

  test('combo bonus for 3+ hits in a swipe', () {
    final state = ScoreState();
    for (var i = 0; i < 3; i++) {
      state.registerHit();
    }
    state.endSwipe();
    expect(state.score,
        3 * ScoreState.pointsPerLetter + 3 * ScoreState.comboBonusPerLetter);
  });

  test('endSwipe resets the per-swipe counter', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
    expect(state.hitsInSwipe, 0);
  });

  test('reset zeroes everything', () {
    final state = ScoreState();
    state.registerHit();
    state.reset();
    expect(state.score, 0);
    expect(state.hitsInSwipe, 0);
  });

  test('bestCombo records the largest chain of the run', () {
    final state = ScoreState();
    expect(state.bestCombo, 0);
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 1);
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 3);
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 3); // smaller swipe doesn't shrink it
  });

  test('reset clears bestCombo', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    state.reset();
    expect(state.bestCombo, 0);
  });
}
