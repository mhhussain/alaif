import 'package:flame/components.dart';

import 'alaif_game.dart';

class Hud extends TextComponent with HasGameReference<AlaifGame> {
  Hud() : super(position: Vector2(16, 48), priority: 90);

  @override
  void update(double dt) {
    text = 'Score ${game.scoreState.score}   Lives ${game.rules.lives}';
  }
}
