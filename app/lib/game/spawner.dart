import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';

class Spawner extends Component with HasGameReference<AlaifGame> {
  Spawner({Random? random}) : _random = random ?? Random();

  final Random _random;
  final DifficultyCurve _curve = DifficultyCurve();
  double _elapsed = 0;
  double _untilNext = 0.5; // quick first spawn; thereafter the curve governs

  @override
  void update(double dt) {
    if (!game.isPlaying) return;
    _elapsed += dt;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      _spawn();
      _untilNext = _curve.spawnInterval(_elapsed);
    }
  }

  void _spawn() {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    // Drift toward screen center; apex lands at 70–95% of screen height.
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy = -screen.y * (0.877 + 0.145 * _random.nextDouble());
    final motion = ArcMotion(
      start: start,
      velocity: Vector2(vx, vy),
      gravity: screen.y * 0.55,
    );

    if (_random.nextDouble() < _curve.bombChance(_elapsed)) {
      game.add(BombComponent(motion: motion));
    } else {
      final letter =
          GlyphAtlas.letters[_random.nextInt(GlyphAtlas.letters.length)];
      game.add(LetterComponent(
        letter: letter,
        image: game.atlas.imageFor(letter),
        motion: motion,
      ));
    }
  }
}
