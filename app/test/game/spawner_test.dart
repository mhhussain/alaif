import 'dart:math';

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/spawner.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('spawner emits letters or bombs over time',
      AlaifGame.new, (game) async {
    game.add(Spawner(random: Random(42)));
    game.update(0); // mount

    // Advance well past the first spawn delay in small ticks.
    for (var i = 0; i < 30; i++) {
      game.update(0.1);
    }

    final flying = game.children.whereType<LetterComponent>().length +
        game.children.whereType<BombComponent>().length;
    expect(flying, greaterThan(0));
  });

  testWithGame<AlaifGame>('startGame installs exactly one spawner',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<Spawner>().length, 1);
  });
}
