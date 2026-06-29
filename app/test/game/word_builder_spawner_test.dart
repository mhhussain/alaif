import 'dart:math';
import 'package:alaif/core/word_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/word_builder_spawner.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alaif/core/game_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('spawner emits letters from the current word over time',
      AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);

    // Advance past the first cluster interval
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }

    final letters = game.children.whereType<LetterComponent>().toList();
    expect(letters, isNotEmpty);
    final wordLetters = game.wordState.currentWord.split('');
    for (final l in letters) {
      expect(wordLetters, contains(l.letter));
    }
  });

  testWithGame<AlaifGame>('spawned letters have a non-null wordIndex',
      AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }
    for (final l in game.children.whereType<LetterComponent>()) {
      expect(l.wordIndex, isNotNull);
    }
  });

  testWithGame<AlaifGame>(
      'spawner does not emit when word is empty', AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);
    game.wordState.reset(); // clear the word
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }
    expect(game.children.whereType<LetterComponent>(), isEmpty);
  });
}
