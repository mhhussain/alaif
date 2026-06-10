import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

/// SFX wrapper around flame_audio.
///
/// EVERY failure here is non-fatal and silent by design: bomb/combo/miss
/// files don't exist yet (stubs awaiting real CC0 sounds), test environments
/// have no audio backend, and a lost sound must never crash gameplay.
/// [enabled] is driven by the persisted settings.
class AudioService {
  bool enabled = true;

  static const sliceSfx = 'slice.mp3'; // real, bundled
  static const bombSfx = 'bomb.mp3'; // stub — may be missing
  static const comboSfx = 'combo.mp3'; // stub — may be missing
  static const missSfx = 'miss.mp3'; // stub — may be missing

  /// Warm the cache. flame_audio resolves names under assets/audio/.
  Future<void> preload() async {
    for (final sfx in const [sliceSfx, bombSfx, comboSfx, missSfx]) {
      try {
        await FlameAudio.audioCache.load(sfx);
      } catch (_) {
        // Missing or unloadable SFX: fine, play() will also no-op.
      }
    }
  }

  void _play(String sfx) {
    if (!enabled) return;
    try {
      unawaited(
        FlameAudio.play(sfx).then<void>((_) {}).catchError((_) {}),
      );
    } catch (_) {
      // Synchronous audio failures are equally non-fatal.
    }
  }

  void playSlice() => _play(sliceSfx);
  void playBomb() => _play(bombSfx);
  void playCombo() => _play(comboSfx);
  void playMiss() => _play(missSfx);
}
