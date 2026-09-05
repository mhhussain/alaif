import 'dart:math';

import 'package:flame/components.dart';

import 'alaif_game.dart';
import 'launch_arc.dart';
import 'letter_component.dart';

class WordBuilderSpawner extends Component with HasGameReference<AlaifGame> {
  WordBuilderSpawner({Random? random}) : _random = random ?? Random();

  static const clusterInterval = 2.0;
  // Spec proposed [1, 3, 5]; 5-glyph clusters crowded small screens after
  // on-device tuning, so capped at 3.
  static const _clusterSizes = [1, 3];

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
    game.add(LetterComponent(
      letter: letter,
      image: game.atlas.imageFor(letter),
      motion: randomLaunchArc(game.size, _random),
      targetSize: randomGlyphTargetSize(_random),
      random: _random,
      wordIndex: wordIndex,
    ));
  }
}
