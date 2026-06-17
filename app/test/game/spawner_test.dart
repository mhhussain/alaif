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

  int liveItems(AlaifGame game) =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  /// Replaces the auto-installed spawner with a seeded one so spawns are
  /// deterministic, and returns it.
  Spawner reseed(AlaifGame game, int seed) {
    game.startGame();
    game.update(0);
    game.children
        .whereType<Spawner>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.update(0);
    final spawner = Spawner(random: Random(seed));
    game.add(spawner);
    game.update(0); // mount
    return spawner;
  }

  testWithGame<AlaifGame>('spawner emits items over time', AlaifGame.new,
      (game) async {
    reseed(game, 42);
    for (var i = 0; i < 30; i++) {
      game.update(0.1);
    }
    expect(liveItems(game), greaterThan(0));
  });

  testWithGame<AlaifGame>('startGame installs exactly one spawner',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<Spawner>().length, 1);
  });

  testWithGame<AlaifGame>('spawnItem adds a bomb when bomb: true',
      AlaifGame.new, (game) async {
    final spawner = reseed(game, 1);
    spawner.spawnItem(bomb: true, speedMultiplier: 1.0);
    game.update(0);
    expect(game.children.whereType<BombComponent>().length, 1);
    expect(game.children.whereType<LetterComponent>().length, 0);
  });

  testWithGame<AlaifGame>('spawnItem adds a letter when bomb: false',
      AlaifGame.new, (game) async {
    final spawner = reseed(game, 1);
    spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
    game.update(0);
    expect(game.children.whereType<LetterComponent>().length, 1);
    expect(game.children.whereType<BombComponent>().length, 0);
  });

  testWithGame<AlaifGame>('atCapacity true once at the cap', AlaifGame.new,
      (game) async {
    final spawner = reseed(game, 1);
    expect(spawner.atCapacity, isFalse);
    for (var i = 0; i < Spawner.maxConcurrentItems; i++) {
      spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
      game.update(0);
    }
    expect(liveItems(game), Spawner.maxConcurrentItems);
    expect(spawner.atCapacity, isTrue);
  });

  testWithGame<AlaifGame>('baseline never exceeds the concurrency cap',
      AlaifGame.new, (game) async {
    reseed(game, 7);
    // Long run; baseline must keep emitting but stay capped.
    for (var i = 0; i < 400; i++) {
      game.update(0.1);
    }
    expect(liveItems(game), lessThanOrEqualTo(Spawner.maxConcurrentItems));
  });
}
