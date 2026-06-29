import 'package:alaif/core/game_mode.dart';
import 'package:alaif/services/high_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads 0 when nothing stored', () async {
    expect(await HighScoreStore().read(), 0);
  });

  test('submit stores a new high score', () async {
    final store = HighScoreStore();
    await store.submit(120);
    expect(await store.read(), 120);
  });

  test('submit ignores lower scores', () async {
    final store = HighScoreStore();
    await store.submit(120);
    await store.submit(50);
    expect(await store.read(), 120);
  });

  test('classic and wordBuilder have separate high scores', () async {
    final store = HighScoreStore();
    await store.submit(500, mode: GameMode.classic);
    await store.submit(300, mode: GameMode.wordBuilder);
    expect(await store.read(mode: GameMode.classic), 500);
    expect(await store.read(mode: GameMode.wordBuilder), 300);
  });

  test('default mode is classic — existing key is unchanged', () async {
    final store = HighScoreStore();
    await store.submit(200);
    expect(await store.read(), 200);
  });
}
