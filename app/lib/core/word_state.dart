class WordState {
  static const pointsPerThreeLetter = 100;
  static const pointsPerFourLetter = 150;
  static const pointsPerFiveLetter = 200;

  String _currentWord = '';
  int _targetIndex = 0;

  String get currentWord => _currentWord;
  int get targetIndex => _targetIndex;
  bool get wordComplete => _targetIndex >= _currentWord.length;

  String get currentTarget {
    if (wordComplete) throw StateError('No current target: word is complete or empty');
    return _currentWord[_targetIndex];
  }

  int get pointsForCurrentWord => switch (_currentWord.length) {
    3 => pointsPerThreeLetter,
    4 => pointsPerFourLetter,
    _ => pointsPerFiveLetter,
  };

  void setWord(String word) {
    _currentWord = word;
    _targetIndex = 0;
  }

  void advanceTarget() {
    _targetIndex++;
  }

  void reset() {
    _currentWord = '';
    _targetIndex = 0;
  }
}
