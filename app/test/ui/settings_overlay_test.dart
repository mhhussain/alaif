import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/settings_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AlaifGame> pumpSettings(WidgetTester tester) async {
    final game = AlaifGame();
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: SettingsOverlay(game: game)),
    ));
    await tester.pumpAndSettle();
    return game;
  }

  testWidgets('settings shows all rows, best score, footer, and Done',
      (tester) async {
    SharedPreferences.setMockInitialValues({'highScore': 70});
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('Best score'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Alaif · v1.0 · made offline'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('switches default to on', (tester) async {
    await pumpSettings(tester);
    for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(s.value, isTrue);
    }
  });

  testWidgets('toggling sound persists and silences the audio service',
      (tester) async {
    final game = await pumpSettings(tester);
    expect(game.audio.enabled, isTrue);

    await tester.tap(find.byType(Switch).first); // rows render in order: sound first
    await tester.pumpAndSettle();

    expect(game.audio.enabled, isFalse);
    expect(await game.settings.soundEnabled(), isFalse);
  });

  testWidgets(
      'switches reflect service state on the very first frame (no flash)',
      (tester) async {
    final game = AlaifGame();
    game.audio.musicEnabled = false;
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: SettingsOverlay(game: game)),
    ));
    await tester.pump(); // first frame only, no settle

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches[1].value, isFalse); // Music row
  });

  testWidgets('toggling music persists and controls the audio service',
      (tester) async {
    final game = await pumpSettings(tester);
    expect(game.audio.musicEnabled, isTrue);

    await tester.tap(find.byType(Switch).at(1)); // second row: music
    await tester.pumpAndSettle();

    expect(game.audio.musicEnabled, isFalse);
    expect(await game.settings.musicEnabled(), isFalse);
  });

  testWidgets('toggling haptics persists and disables the haptics service',
      (tester) async {
    final game = await pumpSettings(tester);

    await tester.tap(find.byType(Switch).at(2)); // third row: haptics
    await tester.pumpAndSettle();

    expect(game.haptics.enabled, isFalse);
    expect(await game.settings.hapticsEnabled(), isFalse);
  });
}
