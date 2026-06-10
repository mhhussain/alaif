import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/game_over_overlay.dart';
import 'package:alaif/ui/menu_overlay.dart';
import 'package:alaif/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'highScore': 70}));

  testWidgets('menu shows wordmark, best score, Play, and links', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: MenuOverlay(game: AlaifGame())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Alaif'), findsOneWidget);
    expect(find.text('A SLICING GAME'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
  });

  testWidgets('game over shows final score, stats, and both actions',
      (tester) async {
    final game = AlaifGame();
    game.scoreState.registerHit(); // final score 10 ≠ best combo 0
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: GameOverOverlay(game: game)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('The blade rests'), findsOneWidget);
    expect(find.text('FINAL SCORE'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('70'), findsOneWidget); // from mocked prefs
    expect(find.text('BEST COMBO'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // best combo this run
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Main menu'), findsOneWidget);
  });

  testWidgets('pause overlay shows score and all four actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: PauseOverlay(game: AlaifGame())),
    ));
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('CURRENT SCORE'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Quit to menu'), findsOneWidget);
  });
}
