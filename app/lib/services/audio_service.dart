import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

/// SFX wrapper around flame_audio.
///
/// EVERY failure here is non-fatal and silent by design: bomb/combo/miss
/// files don't exist yet (stubs awaiting real CC0 sounds), test environments
/// have no audio backend, and a lost sound must never crash gameplay.
/// [enabled] is driven by the persisted settings.
class AudioService {
  AudioService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool enabled = true;

  static const sliceSfx = 'slice.mp3'; // real, bundled
  static const bombSfx = 'bomb.mp3'; // stub — may be missing
  static const comboSfx = 'combo.mp3'; // stub — may be missing
  static const missSfx = 'miss.mp3'; // stub — may be missing
  static const backgroundMusic = 'background.mp3';
  static const musicVolume = 0.5;

  /// Minimum gap between two `playSlice()` calls that actually play. Guards
  /// against overlapping audio if a single swipe slices the same letter (or
  /// produces multiple slice events) within one frame/gesture-tick.
  static const sliceCooldown = Duration(milliseconds: 60);

  final DateTime Function() _now;
  DateTime? _lastSliceAt;

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
    playInternal(sfx);
  }

  /// Performs the actual playback. Split out so tests can override it
  /// without touching FlameAudio (which has no backend in test environments).
  void playInternal(String sfx) {
    try {
      unawaited(
        FlameAudio.play(sfx).then<void>((_) {}).catchError((_) {}),
      );
    } catch (_) {
      // Synchronous audio failures are equally non-fatal.
    }
  }

  void playSlice() {
    if (!enabled) return;
    final now = _now();
    final last = _lastSliceAt;
    if (last != null && now.difference(last) < sliceCooldown) return;
    _lastSliceAt = now;
    playInternal(sliceSfx);
  }

  void playBomb() => _play(bombSfx);
  void playCombo() => _play(comboSfx);
  void playMiss() => _play(missSfx);

  /// Starts the looping background music track. Safe to call repeatedly;
  /// failures (missing file, no audio backend in tests) are silent.
  Future<void> playBackgroundMusic() async {
    if (!enabled) return;
    await playBackgroundMusicInternal();
  }

  /// Performs the actual bgm playback. Split out so tests can override it
  /// without touching FlameAudio (which has no backend in test environments).
  Future<void> playBackgroundMusicInternal() async {
    try {
      await FlameAudio.bgm.play(backgroundMusic, volume: musicVolume);
    } catch (_) {
      // Missing file or no audio backend: non-fatal.
    }
  }

  void pauseBackgroundMusic() => pauseBackgroundMusicInternal();

  void pauseBackgroundMusicInternal() {
    try {
      FlameAudio.bgm.pause();
    } catch (_) {
      // No audio backend: non-fatal.
    }
  }

  void resumeBackgroundMusic() {
    if (!enabled) return;
    resumeBackgroundMusicInternal();
  }

  void resumeBackgroundMusicInternal() {
    try {
      FlameAudio.bgm.resume();
    } catch (_) {
      // No audio backend: non-fatal.
    }
  }
}
