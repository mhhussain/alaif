class ScoreState {
  static const pointsPerLetter = 10;
  static const comboThreshold = 3;
  static const comboBonusPerLetter = 5;

  int _score = 0;
  int _hitsInSwipe = 0;
  int _bestCombo = 0;

  int get score => _score;
  int get hitsInSwipe => _hitsInSwipe;

  /// Largest chain (hits in a single swipe) seen this run.
  int get bestCombo => _bestCombo;

  void registerHit() {
    _hitsInSwipe += 1;
    _score += pointsPerLetter;
  }

  void endSwipe() {
    if (_hitsInSwipe > _bestCombo) _bestCombo = _hitsInSwipe;
    if (_hitsInSwipe >= comboThreshold) {
      _score += _hitsInSwipe * comboBonusPerLetter;
    }
    _hitsInSwipe = 0;
  }

  void reset() {
    _score = 0;
    _hitsInSwipe = 0;
    _bestCombo = 0;
  }
}
