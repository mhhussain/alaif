import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_mode.dart';

class HighScoreStore {
  static String _key(GameMode mode) =>
      mode == GameMode.classic ? 'highScore' : 'highScore.wordBuilder';

  Future<int> read({GameMode mode = GameMode.classic}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key(mode)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> submit(int score, {GameMode mode = GameMode.classic}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(mode);
      if (score > (prefs.getInt(key) ?? 0)) {
        await prefs.setInt(key, score);
      }
    } catch (_) {
      // A lost high score must never crash gameplay.
    }
  }
}
