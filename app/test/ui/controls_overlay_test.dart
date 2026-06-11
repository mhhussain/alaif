import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/controls_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('controls overlay shows a pause icon button', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('controls overlay is positioned top-right via Align',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    final align = tester.widget<Align>(find.ancestor(
      of: find.byType(IconButton),
      matching: find.byType(Align),
    ));
    expect(align.alignment, Alignment.topRight);
  });

  testWidgets(
      'pause button sits below the HUD lives-dot row, clearing the overlap',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    final paddings = tester.widgetList<Padding>(find.ancestor(
      of: find.byType(IconButton),
      matching: find.byType(Padding),
    ));

    // HUD lives dots are centered at y=30 (AlaifSpacing.lg + 14) with a 7px
    // radius, so they end at y=37 within the safe area. The pause button's
    // top padding must clear that.
    final maxTop = paddings
        .map((p) => p.padding.resolve(TextDirection.ltr).top)
        .reduce((a, b) => a > b ? a : b);
    expect(maxTop, greaterThanOrEqualTo(37));
  });

  testWidgets('tapping the pause button calls game.pauseGame and shows paused overlay',
      (tester) async {
    final game = AlaifGame();
    await tester.pumpWidget(GameWidget<AlaifGame>(
      game: game,
      overlayBuilderMap: {
        'controls': (context, game) => ControlsOverlay(game: game),
      },
      initialActiveOverlays: const ['controls'],
    ));
    await tester.pump();
    await tester.pump();

    game.startGame();
    await tester.pump();

    expect(game.isPlaying, isTrue);
    expect(game.paused, isFalse);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(game.paused, isTrue);
    expect(game.overlays.isActive('paused'), isTrue);
  });
}
