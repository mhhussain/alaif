import 'package:alaif/core/score_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('swipePoints formula: 10 * cuts * min(cuts, 4)', () {
    expect(ScoreState.swipePoints(1), 10);
    expect(ScoreState.swipePoints(2), 40);
    expect(ScoreState.swipePoints(3), 90);
    expect(ScoreState.swipePoints(4), 160);
    expect(ScoreState.swipePoints(5), 200);
    expect(ScoreState.swipePoints(6), 240);
    expect(ScoreState.swipePoints(0), 0);
  });

  test('score updates only at endSwipe (whole-swipe multiplier)', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    expect(state.score, 0); // nothing banked mid-swipe
    state.endSwipe();
    expect(state.score, 40); // 10 * 2 * 2
  });

  test('single-cut swipe scores 10', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
    expect(state.score, 10);
  });

  test('multiplier caps at x4', () {
    final state = ScoreState();
    for (var i = 0; i < 5; i++) {
      state.registerHit();
    }
    state.endSwipe();
    expect(state.score, 200); // 10 * 5 * 4
  });

  test('scores accumulate across swipes', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.endSwipe(); // +40
    state.registerHit();
    state.endSwipe(); // +10
    expect(state.score, 50);
  });

  test('endSwipe resets the per-swipe counter', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
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
    expect(state.bestCombo, 3);
  });

  test('reset zeroes everything', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    state.reset();
    expect(state.score, 0);
    expect(state.hitsInSwipe, 0);
    expect(state.bestCombo, 0);
  });

  test('addPoints increases score directly', () {
    final s = ScoreState();
    s.addPoints(150);
    expect(s.score, 150);
    s.addPoints(50);
    expect(s.score, 200);
  });
}
