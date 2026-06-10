import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, SizedBox;

import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'paper_background.dart';
import 'sliced_halves.dart';
import 'spawner.dart';

class AlaifGame extends FlameGame {
  AlaifGame({HighScoreStore? highScores})
      : highScores = highScores ?? HighScoreStore();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;

  bool _playing = false;
  bool get isPlaying => _playing;

  bool _hudInstalled = false;

  @override
  Color backgroundColor() => AlaifColors.paper;

  @override
  Future<void> onLoad() async {
    await atlas.load();
    await add(PaperBackground());
    // Register fallback builders so overlays.add/isActive work in test
    // environments where no GameWidget overlay entries are provided.
    for (final name in const ['menu', 'gameOver', 'paused', 'controls']) {
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
        _checkGameOver();
      }
    }
  }

  /// Called by BladeTrail when the finger lifts.
  void endSwipe() => scoreState.endSwipe();

  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    letter.removeFromParent();
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

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseGame();
  }
}
