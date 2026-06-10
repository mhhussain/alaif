import 'package:alaif/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('everything defaults to enabled', () async {
    final store = SettingsStore();
    expect(await store.soundEnabled(), isTrue);
    expect(await store.musicEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isTrue);
  });

  test('set/read round-trips each flag independently', () async {
    final store = SettingsStore();
    await store.setSoundEnabled(false);
    await store.setHapticsEnabled(false);
    expect(await store.soundEnabled(), isFalse);
    expect(await store.musicEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isFalse);

    await store.setSoundEnabled(true);
    expect(await store.soundEnabled(), isTrue);
  });

  test('corrupt stored values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'settings.sound': 'definitely-not-a-bool',
      'settings.haptics': 42,
    });
    final store = SettingsStore();
    expect(await store.soundEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isTrue);
  });
}
