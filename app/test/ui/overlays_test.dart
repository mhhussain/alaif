import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/game_over_overlay.dart';
import 'package:alaif/ui/menu_overlay.dart';
import 'package:alaif/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'highScore': 70}));

  testWidgets('menu shows title, best score, and Play', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MenuOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();
    expect(find.text('Alaif'), findsOneWidget);
    expect(find.text('Best: 70'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('game over shows final score and Play Again', (tester) async {
    final game = AlaifGame();
    await tester
        .pumpWidget(MaterialApp(home: GameOverOverlay(game: game)));
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
  });

  testWidgets('pause overlay shows Resume', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: PauseOverlay(game: AlaifGame())));
    expect(find.text('Resume'), findsOneWidget);
  });
}
