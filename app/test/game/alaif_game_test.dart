import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/audio_service.dart';
import 'package:alaif/services/haptics_service.dart';
import 'package:alaif/ui/design_tokens.dart';
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

class RecordingHaptics extends HapticsService {
  final events = <String>[];
  @override
  void onSlice() => events.add('slice');
  @override
  void onBomb() => events.add('bomb');
  @override
  void onMiss() => events.add('miss');
}

class RecordingAudio extends AudioService {
  final events = <String>[];
  @override
  Future<void> preload() async => events.add('preload');
  @override
  void playSlice() => events.add('slice');
  @override
  void playBomb() => events.add('bomb');
  @override
  void playCombo() => events.add('combo');
  @override
  void playMiss() => events.add('miss');
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

  testWithGame<AlaifGame>(
      'a letter already sliced this frame is not sliced again by a later segment',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0); // mount

    // Two swipe segments both cross the same letter before removal is
    // processed (Flame defers removeFromParent to the next update tick).
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process removal/additions

    expect(game.scoreState.score, ScoreState.pointsPerLetter);
    expect(game.children.whereType<SlicedHalf>().length, 2);
  });

  testWithGame<AlaifGame>(
      'a vertical swipe produces sliced halves whose cut direction matches the swipe',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0); // mount

    // Vertical swipe (top to bottom) through the letter's position.
    game.trySlice(Vector2(100, 200), Vector2(100, 400));
    game.update(0);

    final halves = game.children.whereType<SlicedHalf>().toList();
    expect(halves.length, 2);
    for (final half in halves) {
      // cutDirection should be (close to) vertical: |y| component dominates.
      expect(half.cutDirection.x.abs(), lessThan(half.cutDirection.y.abs()));
      // Cut passes through the letter's center.
      expect(half.cutCenter, letter.size / 2);
    }
    // The two halves must separate from each other (different velocities).
    expect(halves[0].velocity, isNot(equals(halves[1].velocity)));
  });

  testWithGame<AlaifGame>(
      'slicing a rotated letter bakes the cut and halves at the letter\'s angle',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0); // mount

    // Give the letter a known non-zero rotation, as if it had spawned with a
    // toss and/or tumbled mid-flight.
    const letterAngle = 0.3;
    letter.angle = letterAngle;

    final swipeFrom = Vector2(100, 200);
    final swipeTo = Vector2(100, 400);
    game.trySlice(swipeFrom, swipeTo);
    game.update(0); // process removal/additions

    final halves = game.children.whereType<SlicedHalf>().toList();
    expect(halves.length, 2);

    final worldDirection = (swipeTo - swipeFrom).normalized();
    final expectedLocalDirection = rotateVector(worldDirection, -letterAngle);

    for (final half in halves) {
      expect(half.angle, closeTo(letterAngle, 1e-9));
      expect(half.cutDirection.x, closeTo(expectedLocalDirection.x, 1e-9));
      expect(half.cutDirection.y, closeTo(expectedLocalDirection.y, 1e-9));
    }
  });

  testWithGame<AlaifGame>(
      'a degenerate (zero-length) swipe segment falls back to a horizontal cut',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0);

    // from == to: zero-length segment, but it still must hit (radius covers point).
    game.trySlice(Vector2(100, 300), Vector2(100, 300));
    game.update(0);

    final halves = game.children.whereType<SlicedHalf>().toList();
    expect(halves.length, 2);
    for (final half in halves) {
      expect(half.cutDirection, Vector2(1, 0));
    }
  });

  testWithGame<AlaifGame>(
      'a fast swipe produces a larger half-separation impulse than a slow one',
      AlaifGame.new, (game) async {
    game.startGame();

    final slowLetter = staticLetter(game, x: 100, y: 300);
    game.add(slowLetter);
    game.update(0);
    game.trySlice(Vector2(99, 300), Vector2(101, 300)); // tiny 2px segment
    game.update(0);
    final slowHalves = game.children.whereType<SlicedHalf>().toList();
    final slowSpeed = slowHalves.first.velocity.length;

    game.startGame(); // clears halves and resets state

    final fastLetter = staticLetter(game, x: 100, y: 300);
    game.add(fastLetter);
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(800, 300)); // large fast segment
    game.update(0);
    final fastHalves = game.children.whereType<SlicedHalf>().toList();
    final fastSpeed = fastHalves.first.velocity.length;

    expect(fastSpeed, greaterThan(slowSpeed));
    // Even the fast swipe is clamped.
    // velocity = perp * separationSpeed + popVelocity (0, -100), so its
    // magnitude is bounded by the clamped separation speed plus the pop
    // velocity's length.
    const popVelocityLength = 100.0; // matches AlaifGame's _halfPopVelocity
    expect(
      fastSpeed,
      lessThanOrEqualTo(AlaifMotion.cutSeparationMaxSpeed + popVelocityLength),
    );
  });

  testWithGame<AlaifGame>(
      'slicing a letter triggers a brief hit-stop that scales down dt for the simulation',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game, x: 100, y: 300);
    game.add(letter);
    game.update(0); // mount

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process slice

    final half = game.children.whereType<SlicedHalf>().first;
    final yBefore = half.position.y;

    // During hit-stop, a real-time-sized dt should barely move the half.
    final hitStopDt = AlaifMotion.hitStopMs / 1000;
    game.update(hitStopDt);
    final yDuringHitStop = half.position.y;
    expect(yDuringHitStop - yBefore, lessThan(1.0));

    // After the hit-stop window elapses, the same dt advances normally.
    game.update(hitStopDt);
    final yAfterHitStop = half.position.y;
    expect(yAfterHitStop - yDuringHitStop, greaterThan(1.0));
  });

  testWithGame<AlaifGame>('hit-stop does not affect the game when no slice has occurred',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = LetterComponent(
      letter: 'ب',
      image: game.atlas.imageFor('ب'),
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2(0, 100), gravity: 0),
    );
    game.add(letter);
    game.update(0); // mount

    final yBefore = letter.position.y;
    game.update(0.1);
    expect(letter.position.y - yBefore, closeTo(10, 1e-9)); // unscaled dt
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

  testWithGame<AlaifGame>(
      'controls overlay is shown while playing and hidden on game over',
      AlaifGame.new, (game) async {
    expect(game.overlays.isActive('controls'), isFalse);

    game.startGame();
    expect(game.overlays.isActive('controls'), isTrue);

    game.rules.onBombSliced();
    game.rules.onBombSliced();
    game.rules.onBombSliced();
    final letter = staticLetter(game)..entered = true;
    game.add(letter);
    game.update(0);
    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.isPlaying, isFalse);
    expect(game.overlays.isActive('gameOver'), isTrue);
    expect(game.overlays.isActive('controls'), isFalse);
  });

  testWithGame<AlaifGame>(
      'pausing hides controls and resuming restores them',
      AlaifGame.new, (game) async {
    game.startGame();
    expect(game.overlays.isActive('controls'), isTrue);

    game.pauseGame();
    expect(game.overlays.isActive('paused'), isTrue);
    expect(game.overlays.isActive('controls'), isFalse);

    game.resumeFromPause();
    expect(game.overlays.isActive('paused'), isFalse);
    expect(game.overlays.isActive('controls'), isTrue);
  });

  testWithGame<AlaifGame>('slicing a letter throws an ink burst',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);

    expect(game.children.whereType<InkBurstComponent>().length, 1);
  });

  testWithGame<AlaifGame>('a 3-letter swipe shows the combo callout and gold dust',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.add(staticLetter(game, x: 280));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.update(0);
    game.endSwipe();
    game.update(0);

    final callouts = game.children.whereType<ComboCallout>().toList();
    expect(callouts.length, 1);
    expect(callouts.single.text, 'three in a row');
    // One ink burst per letter + one gold-dust combo burst.
    expect(game.children.whereType<InkBurstComponent>().length, 4);
    expect(game.scoreState.bestCombo, 3);
  });

  testWithGame<AlaifGame>('a 2-letter swipe shows no combo callout',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.update(0);
    game.endSwipe();
    game.update(0);

    expect(game.children.whereType<ComboCallout>(), isEmpty);
  });

  testWithGame<AlaifGame>('haptics fire on slice, bomb, and miss',
      () => AlaifGame(haptics: RecordingHaptics()), (game) async {
    final haptics = game.haptics as RecordingHaptics;
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    expect(haptics.events, ['slice']);

    game.add(BombComponent(
      motion: ArcMotion(
          start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    ));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    expect(haptics.events, ['slice', 'bomb']);

    final missed = staticLetter(game)..entered = true;
    game.add(missed);
    game.update(0);
    missed.position.y = game.size.y + 500;
    game.update(0);
    expect(haptics.events, ['slice', 'bomb', 'miss']);
  });

  testWithGame<AlaifGame>('audio preloads and fires on slice and combo',
      () => AlaifGame(audio: RecordingAudio()), (game) async {
    final audio = game.audio as RecordingAudio;
    expect(audio.events, contains('preload'));

    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.add(staticLetter(game, x: 280));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.endSwipe();

    expect(audio.events.where((e) => e == 'slice').length, 3);
    expect(audio.events, contains('combo'));
  });

  testWithGame<AlaifGame>('persisted settings flags reach audio and haptics',
      () {
    SharedPreferences.setMockInitialValues({
      'settings.sound': false,
      'settings.haptics': false,
    });
    return AlaifGame();
  }, (game) async {
    expect(game.audio.enabled, isFalse);
    expect(game.haptics.enabled, isFalse);
  });

  testWithGame<AlaifGame>('how-to opens from the menu and returns to it',
      AlaifGame.new, (game) async {
    expect(game.overlays.isActive('menu'), isTrue);
    game.openHowTo();
    expect(game.overlays.isActive('howTo'), isTrue);
    expect(game.overlays.isActive('menu'), isFalse);
    game.closeHowTo();
    expect(game.overlays.isActive('menu'), isTrue);
    expect(game.overlays.isActive('howTo'), isFalse);
  });

  testWithGame<AlaifGame>('settings remembers where it was opened from',
      AlaifGame.new, (game) async {
    game.openSettings(from: 'menu');
    expect(game.overlays.isActive('settings'), isTrue);
    expect(game.overlays.isActive('menu'), isFalse);
    game.closeSettings();
    expect(game.overlays.isActive('menu'), isTrue);

    game.startGame();
    game.pauseGame();
    game.openSettings(from: 'paused');
    expect(game.overlays.isActive('settings'), isTrue);
    expect(game.overlays.isActive('paused'), isFalse);
    game.closeSettings();
    expect(game.overlays.isActive('paused'), isTrue);
  });

  testWithGame<AlaifGame>('quitToMenu clears the board and returns to menu',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);
    game.pauseGame();

    game.quitToMenu();
    game.update(0);
    expect(game.paused, isFalse); // engine resumed so the menu animates
    expect(game.isPlaying, isFalse);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
    expect(game.overlays.isActive('menu'), isTrue);
    expect(game.overlays.isActive('paused'), isFalse);
    expect(game.overlays.isActive('controls'), isFalse);
  });
}
