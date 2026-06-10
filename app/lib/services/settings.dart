import 'package:shared_preferences/shared_preferences.dart';

/// Persisted player settings. Defaults are all ON; corrupt or missing
/// preferences silently fall back to defaults — settings must never crash
/// or block the game.
class SettingsStore {
  static const _soundKey = 'settings.sound';
  static const _musicKey = 'settings.music';
  static const _hapticsKey = 'settings.haptics';

  Future<bool> soundEnabled() => _readBool(_soundKey);
  Future<void> setSoundEnabled(bool value) => _writeBool(_soundKey, value);

  Future<bool> musicEnabled() => _readBool(_musicKey);
  Future<void> setMusicEnabled(bool value) => _writeBool(_musicKey, value);

  Future<bool> hapticsEnabled() => _readBool(_hapticsKey);
  Future<void> setHapticsEnabled(bool value) => _writeBool(_hapticsKey, value);

  Future<bool> _readBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true; // corrupt value or unavailable prefs → default ON
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // A lost setting must never crash the game.
    }
  }
}
