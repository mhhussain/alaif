import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';
import 'letter_component.dart';

class WordBuilderSpawner extends Component with HasGameReference<AlaifGame> {
  WordBuilderSpawner({Random? random}) : _random = random ?? Random();

  static const clusterInterval = 2.0;
  static const _clusterSizes = [1, 3];

  /// Max radians a single launch is rotated off its base arc (~7°), so a
  /// cluster spawned in one tick spreads out instead of stacking.
  static const launchJitter = 0.12;

  final Random _random;
  double _untilNext = 0.5;

  @override
  void update(double dt) {
    if (!game.isPlaying || game.isWordPaused) return;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      _spawnCluster();
      _untilNext = clusterInterval;
    }
  }

  void _spawnCluster() {
    final word = game.wordState.currentWord;
    if (word.isEmpty) return;
    final size = _clusterSizes[_random.nextInt(_clusterSizes.length)];
    for (var i = 0; i < size; i++) {
      final wordIndex = _random.nextInt(word.length);
      _spawnLetter(word[wordIndex], wordIndex);
    }
  }

  void _spawnLetter(String letter, int wordIndex) {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy = -screen.y * (0.877 + 0.145 * _random.nextDouble());
    // Per-glyph angle jitter so clustered launches fan out instead of overlapping.
    final velocity = Vector2(vx, vy)
      ..rotate((_random.nextDouble() * 2 - 1) * launchJitter);
    final motion = ArcMotion(
      start: start,
      velocity: velocity,
      gravity: screen.y * 0.55,
    );
    final targetSize = AlaifGlyph.spawnSizeMin +
        (AlaifGlyph.spawnSizeMax - AlaifGlyph.spawnSizeMin) *
            _random.nextDouble();
    game.add(LetterComponent(
      letter: letter,
      image: game.atlas.imageFor(letter),
      motion: motion,
      targetSize: targetSize,
      random: _random,
      wordIndex: wordIndex,
    ));
  }
}
