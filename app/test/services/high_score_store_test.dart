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
}
