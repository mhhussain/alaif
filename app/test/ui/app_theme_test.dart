import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/main.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('AlaifApp installs the Ink & Paper theme', (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.theme!.scaffoldBackgroundColor, AlaifColors.paper);
    expect(app.theme!.colorScheme.primary, AlaifColors.ink);
  });

  testWidgets('AlaifApp scaffold paints the paper background edge-to-edge',
      (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AlaifColors.paper);
  });

  testWidgets('AlaifApp does not wrap the GameWidget in a SafeArea',
      (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    // The game canvas itself must not be inset by SafeArea so it paints
    // edge-to-edge; insets are instead passed into the game for HUD layout.
    // Overlays (e.g. the menu, shown by default) may still have their own
    // SafeArea, so check specifically that GameWidget has no SafeArea
    // ancestor rather than asserting no SafeArea exists anywhere.
    expect(
      find.ancestor(
        of: find.byType(GameWidget<AlaifGame>),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });
}
