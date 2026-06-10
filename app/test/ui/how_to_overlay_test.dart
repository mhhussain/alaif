import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/how_to_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('how-to shows the three lessons and Got it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: HowToOverlay(game: AlaifGame())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Swipe to slice'), findsOneWidget);
    expect(find.text('Chain combos'), findsOneWidget);
    expect(find.text('Avoid the bombs'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}
