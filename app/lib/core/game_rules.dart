class GameRules {
  static const startingLives = 3;

  int _lives = startingLives;

  int get lives => _lives;
  bool get isGameOver => _lives <= 0;

  void onLetterMissed() => _loseLife();
  void onBombSliced() => _loseLife();

  void _loseLife() {
    if (_lives > 0) _lives -= 1;
  }

  void reset() => _lives = startingLives;
}
