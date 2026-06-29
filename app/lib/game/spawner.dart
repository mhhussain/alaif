import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';

/// Baseline spawner. Each tick it reads the current [Stage] from the live
/// score and emits a stage-scaled batch, never exceeding [maxConcurrentItems].
class Spawner extends Component with HasGameReference<AlaifGame> {
  Spawner({Random? random, bool autoSpawn = true})
      : _random = random ?? Random(),
        _autoSpawn = autoSpawn;

  /// Fairness/readability cap: letters + bombs on screen at once.
  static const maxConcurrentItems = 12;

  /// Max radians a single launch is rotated off its base arc (~7°), so a
  /// cluster spawned in one tick spreads out instead of stacking.
  static const launchJitter = 0.12;

  final Random _random;
  final bool _autoSpawn;
  double _untilNext = 0.5; // quick first spawn; thereafter the stage governs

  int get _liveCount =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  bool get atCapacity => _liveCount >= maxConcurrentItems;

  @override
  void update(double dt) {
    if (!game.isPlaying) return;
    if (!_autoSpawn) return;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      final stage = stageFor(game.scoreState.score);
      _spawnBatch(stage);
      _untilNext = stage.baselineInterval;
    }
  }

  void _spawnBatch(Stage stage) {
    final span = stage.batchMax - stage.batchMin + 1;
    final count = stage.batchMin + _random.nextInt(span);
    for (var i = 0; i < count; i++) {
      if (atCapacity) break;
      final bomb = _random.nextDouble() < stage.bombChance;
      spawnItem(bomb: bomb, speedMultiplier: stage.letterSpeed);
    }
  }

  /// Emits one item on a launch arc. [speedMultiplier] scales the vertical
  /// launch speed (stage letter-speed for baseline; boosted for surges).
  void spawnItem({required bool bomb, required double speedMultiplier}) {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    // Drift toward screen center; apex lands at 70–95% of screen height.
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy =
        -screen.y * (0.877 + 0.145 * _random.nextDouble()) * speedMultiplier;
    // Per-glyph angle jitter so clustered launches fan out instead of overlapping.
    final velocity = Vector2(vx, vy)
      ..rotate((_random.nextDouble() * 2 - 1) * launchJitter);
    final motion = ArcMotion(
      start: start,
      velocity: velocity,
      gravity: screen.y * 0.55,
    );

    if (bomb) {
      game.add(BombComponent(motion: motion));
    } else {
      final letter =
          GlyphAtlas.letters[_random.nextInt(GlyphAtlas.letters.length)];
      final targetSize = AlaifGlyph.spawnSizeMin +
          (AlaifGlyph.spawnSizeMax - AlaifGlyph.spawnSizeMin) *
              _random.nextDouble();
      game.add(LetterComponent(
        letter: letter,
        image: game.atlas.imageFor(letter),
        motion: motion,
        targetSize: targetSize,
        random: _random,
      ));
    }
  }
}
