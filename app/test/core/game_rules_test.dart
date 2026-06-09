import 'package:alaif/core/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with 3 lives and not game over', () {
    final rules = GameRules();
    expect(rules.lives, 3);
    expect(rules.isGameOver, isFalse);
  });

  test('three missed letters end the game', () {
    final rules = GameRules();
    rules.onLetterMissed();
    rules.onLetterMissed();
    rules.onLetterMissed();
    expect(rules.isGameOver, isTrue);
  });

  test('slicing a bomb costs a life', () {
    final rules = GameRules();
    rules.onBombSliced();
    expect(rules.lives, 2);
  });

  test('reset restores lives', () {
    final rules = GameRules();
    rules.onBombSliced();
    rules.reset();
    expect(rules.lives, 3);
    expect(rules.isGameOver, isFalse);
  });
}
