import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, SizedBox;

import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/ink_particles.dart';
import '../core/score_state.dart';
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
import '../services/settings.dart';
import '../ui/design_tokens.dart';
import 'bomb_component.dart';
import 'combo_callout.dart';
import 'ink_burst_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'paper_background.dart';
import 'sliced_halves.dart';
import 'spawner.dart';

class AlaifGame extends FlameGame {
  AlaifGame({
    HighScoreStore? highScores,
    AudioService? audio,
    HapticsService? haptics,
    SettingsStore? settings,
    Random? random,
  })  : highScores = highScores ?? HighScoreStore(),
        audio = audio ?? AudioService(),
        haptics = haptics ?? HapticsService(),
        settings = settings ?? SettingsStore(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;
  final AudioService audio;
  final HapticsService haptics;
  final SettingsStore settings;
  String _settingsReturnOverlay = 'menu';
  final Random _random;
  Vector2? _lastSlicePosition;

  bool _playing = false;
  bool get isPlaying => _playing;

  bool _hudInstalled = false;

  @override
  Color backgroundColor() => AlaifColors.paper;

  @override
  Future<void> onLoad() async {
    await atlas.load();
    audio.enabled = await settings.soundEnabled();
    haptics.enabled = await settings.hapticsEnabled();
    unawaited(audio.preload()); // fire-and-forget; failures are silent
    await add(PaperBackground());
    // Register fallback builders so overlays.add/isActive work in test
    // environments where no GameWidget overlay entries are provided.
    for (final name in const [
      'menu',
      'gameOver',
      'paused',
      'controls',
      'howTo',
      'settings',
    ]) {
      if (!overlays.registeredOverlays.contains(name)) {
        overlays.addEntry(name, (_, _) => const SizedBox.shrink());
      }
    }
    overlays.add('menu');
  }

  void startGame() {
    scoreState.reset();
    rules.reset();
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner)
        .toList()
        .forEach((c) => c.removeFromParent());
    add(Spawner());
    if (!_hudInstalled) {
      _hudInstalled = true;
      add(BladeTrail());
      add(Hud());
    }
    if (paused) resumeEngine(); // close the pause-then-restart gap
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
    overlays.remove('paused');
    overlays.add('controls');
  }

  /// Called by BladeTrail for each new swipe segment.
  void trySlice(Vector2 from, Vector2 to) {
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        audio.playBomb();
        _checkGameOver();
      }
    }
  }

  /// Called by BladeTrail when the finger lifts. A 3+ chain earns gold dust
  /// at the last cut plus the centered combo callout (spec §4.3).
  void endSwipe() {
    final hits = scoreState.hitsInSwipe;
    scoreState.endSwipe();
    if (!_playing || hits < ScoreState.comboThreshold) return;
    final at = _lastSlicePosition;
    if (at != null) {
      add(InkBurstComponent(particles: spawnComboBurst(at, _random)));
    }
    add(ComboCallout(text: ComboCallout.comboText(hits)));
    audio.playCombo();
  }

  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    _lastSlicePosition = letter.position.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(letter.position, _random),
    ));
    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(-120, -150),
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(120, -100),
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
  }

  @override
  void update(double dt) {
    // Check positions before super.update so that externally-mutated positions
    // (e.g. in tests) are visible before child update() resets them via ArcMotion.
    if (_playing) {
      for (final letter in children.whereType<LetterComponent>().toList()) {
        if (!letter.entered && letter.position.y < size.y) letter.entered = true;
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
          audio.playMiss();
          _checkGameOver();
        }
      }
      for (final bomb in children.whereType<BombComponent>().toList()) {
        if (!bomb.entered && bomb.position.y < size.y) bomb.entered = true;
        if (bomb.entered && bomb.position.y > size.y + 120) {
          bomb.removeFromParent(); // missing a bomb is free
        }
      }
    }
    super.update(dt);
  }

  void _checkGameOver() {
    if (!rules.isGameOver || !_playing) return;
    _playing = false;
    unawaited(highScores.submit(scoreState.score)); // fire-and-forget by design
    overlays.remove('controls');
    overlays.add('gameOver');
  }

  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    overlays.remove('controls');
    overlays.add('paused');
  }

  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
  }

  void openHowTo() {
    overlays.remove('menu');
    overlays.add('howTo');
  }

  void closeHowTo() {
    overlays.remove('howTo');
    overlays.add('menu');
  }

  /// [from] is the overlay to return to on [closeSettings]: 'menu' or 'paused'.
  void openSettings({required String from}) {
    _settingsReturnOverlay = from;
    overlays.remove(from);
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    overlays.add(_settingsReturnOverlay);
  }

  /// Abandon the current run (from pause or game over) and show the menu.
  void quitToMenu() {
    _playing = false;
    if (paused) resumeEngine();
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner)
        .toList()
        .forEach((c) => c.removeFromParent());
    update(0);
    overlays.remove('paused');
    overlays.remove('gameOver');
    overlays.remove('controls');
    overlays.add('menu');
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseGame();
  }
}
