import 'dart:math';

class ScoreState {
  static const pointsPerLetter = 10;

  /// Minimum hits in one swipe to trigger the combo callout/dust (visual only).
  static const comboThreshold = 3;

  /// The swipe multiplier is capped at this many cuts.
  static const comboMultiplierCap = 4;

  int _score = 0;
  int _hitsInSwipe = 0;
  int _bestCombo = 0;

  int get score => _score;
  int get hitsInSwipe => _hitsInSwipe;

  /// Largest chain (hits in a single swipe) seen this run.
  int get bestCombo => _bestCombo;

  /// Points awarded for a swipe of [cuts] letters: 10 * cuts * min(cuts, 4).
  static int swipePoints(int cuts) =>
      pointsPerLetter * cuts * min(cuts, comboMultiplierCap);

  void registerHit() {
    _hitsInSwipe += 1;
  }

  void endSwipe() {
    if (_hitsInSwipe > _bestCombo) _bestCombo = _hitsInSwipe;
    _score += swipePoints(_hitsInSwipe);
    _hitsInSwipe = 0;
  }

  void reset() {
    _score = 0;
    _hitsInSwipe = 0;
    _bestCombo = 0;
  }
}
