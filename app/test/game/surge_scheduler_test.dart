import 'dart:math';

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/spawner.dart';
import 'package:alaif/game/surge_scheduler.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  int liveItems(AlaifGame game) =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  /// Starts the game, removes the baseline spawner (so only the surge under
  /// test produces items), and installs a seeded scheduler + seeded spawner.
  SurgeScheduler isolateSurge(AlaifGame game, int seed) {
    game.startGame();
    game.update(0);
    game.children
        .whereType<Spawner>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.children
        .whereType<SurgeScheduler>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.update(0);
    game.add(Spawner(random: Random(seed), autoSpawn: false));
    final scheduler = SurgeScheduler(random: Random(seed));
    game.add(scheduler);
    game.update(0); // mount both
    return scheduler;
  }

  testWithGame<AlaifGame>('no surge before the first cadence elapses',
      AlaifGame.new, (game) async {
    isolateSurge(game, 3);
    game.update(1.0); // Calm cadence is 12s; well short
    expect(liveItems(game), 0);
  });

  testWithGame<AlaifGame>('a surge fires after the cadence and emits items',
      AlaifGame.new, (game) async {
    isolateSurge(game, 3);
    game.update(12.0); // reach the Calm cadence -> start surge
    // Drive the sub-spawn timer; Calm surgeCount is 3 at 0.15s apart.
    for (var i = 0; i < 5; i++) {
      game.update(0.15);
    }
    expect(liveItems(game), greaterThan(0));
    expect(liveItems(game), lessThanOrEqualTo(3));
  });

  testWithGame<AlaifGame>('surge respects the concurrency cap', AlaifGame.new,
      (game) async {
    final scheduler = isolateSurge(game, 9);
    // Pre-fill to the cap via the spawner.
    final spawner = game.children.whereType<Spawner>().first;
    for (var i = 0; i < Spawner.maxConcurrentItems; i++) {
      spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
      game.update(0);
    }
    expect(scheduler.isMounted, isTrue);
    game.update(12.0);
    for (var i = 0; i < 10; i++) {
      game.update(0.15);
    }
    expect(liveItems(game), lessThanOrEqualTo(Spawner.maxConcurrentItems));
  });
}
