import 'package:shared_preferences/shared_preferences.dart';

class HighScoreStore {
  static const _key = 'highScore';

  Future<int> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> submit(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (score > (prefs.getInt(_key) ?? 0)) {
        await prefs.setInt(_key, score);
      }
    } catch (_) {
      // A lost high score must never crash gameplay.
    }
  }
}
