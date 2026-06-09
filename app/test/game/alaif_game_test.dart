import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LetterComponent staticLetter(AlaifGame game, {double x = 100, double y = 300}) {
  return LetterComponent(
    letter: 'ب',
    image: game.atlas.imageFor('ب'),
    motion: ArcMotion(start: Vector2(x, y), velocity: Vector2.zero(), gravity: 0),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('startGame resets score and lives', AlaifGame.new,
      (game) async {
    game.startGame();
    expect(game.isPlaying, isTrue);
    expect(game.scoreState.score, 0);
    expect(game.rules.lives, 3);
  });

  testWithGame<AlaifGame>('slicing a letter scores and spawns two halves',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0); // mount

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process removal/additions

    expect(game.scoreState.score, ScoreState.pointsPerLetter);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
    expect(game.children.whereType<SlicedHalf>().length, 2);
  });

  testWithGame<AlaifGame>('slicing a bomb costs a life', AlaifGame.new,
      (game) async {
    game.startGame();
    game.add(BombComponent(
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    ));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);

    expect(game.rules.lives, 2);
  });

  testWithGame<AlaifGame>('a letter falling offscreen after entering costs a life',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game, y: 300)..entered = true;
    game.add(letter);
    game.update(0);

    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.rules.lives, 2);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
  });

  testWithGame<AlaifGame>('losing all lives ends the game and shows overlay',
      AlaifGame.new, (game) async {
    game.startGame();
    game.rules.onBombSliced();
    game.rules.onBombSliced();

    final letter = staticLetter(game)..entered = true;
    game.add(letter);
    game.update(0);
    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.isPlaying, isFalse);
    expect(game.overlays.isActive('gameOver'), isTrue);
  });
}
