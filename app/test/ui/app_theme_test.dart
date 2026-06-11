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

  testWidgets('AlaifApp keeps game safePadding in sync with MediaQuery insets',
      (tester) async {
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);

    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final gameWidget =
        tester.widget<GameWidget<AlaifGame>>(find.byType(GameWidget<AlaifGame>));
    final game = gameWidget.game!;
    final context = tester.element(find.byType(GameWidget<AlaifGame>));
    expect(game.safePadding, MediaQuery.paddingOf(context));
    expect(game.safePadding, const EdgeInsets.only(top: 44, bottom: 34));

    // Simulate an inset change (e.g. rotation) and confirm it propagates.
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 0);
    await tester.pump();

    expect(game.safePadding, const EdgeInsets.only(top: 24, bottom: 0));
  });
}
