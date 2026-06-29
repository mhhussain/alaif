import 'package:alaif/core/word_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is empty', () {
    final ws = WordState();
    expect(ws.currentWord, '');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isTrue);
  });

  test('setWord sets word and resets targetIndex', () {
    final ws = WordState()..setWord('بيت');
    expect(ws.currentWord, 'بيت');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isFalse);
    expect(ws.currentTarget, 'ب');
  });

  test('advanceTarget moves the target forward', () {
    final ws = WordState()..setWord('بيت');
    ws.advanceTarget();
    expect(ws.targetIndex, 1);
    expect(ws.currentTarget, 'ي');
  });

  test('wordComplete is true after all letters are advanced past', () {
    final ws = WordState()..setWord('بيت');
    ws.advanceTarget();
    ws.advanceTarget();
    ws.advanceTarget();
    expect(ws.wordComplete, isTrue);
  });

  test('pointsForCurrentWord: 100 for 3, 150 for 4, 200 for 5', () {
    expect((WordState()..setWord('بيت')).pointsForCurrentWord, 100);
    expect((WordState()..setWord('كتاب')).pointsForCurrentWord, 150);
    expect((WordState()..setWord('سلطان')).pointsForCurrentWord, 200);
  });

  test('reset clears word and index', () {
    final ws = WordState()..setWord('بيت')..advanceTarget();
    ws.reset();
    expect(ws.currentWord, '');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isTrue);
  });
}
