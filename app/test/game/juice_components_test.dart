import 'dart:math';
import 'dart:ui' as ui;

import 'package:alaif/core/ink_particles.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('ink burst renders then removes itself when spent',
      AlaifGame.new, (game) async {
    final burst =
        InkBurstComponent(particles: spawnCutBurst(Vector2(50, 50), Random(1)));
    await game.add(burst);
    game.update(0);
    expect(game.children.whereType<InkBurstComponent>().length, 1);

    final recorder = ui.PictureRecorder();
    burst.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();

    game.update(AlaifMotion.cutParticleLifeMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<InkBurstComponent>(), isEmpty);
  });

  test('comboText spells small chains and counts big ones', () {
    expect(ComboCallout.comboText(3), 'three in a row');
    expect(ComboCallout.comboText(4), 'four in a row');
    expect(ComboCallout.comboText(5), '×5');
    expect(ComboCallout.comboText(9), '×9');
  });

  testWithGame<AlaifGame>('combo callout centers near y150 and fades away',
      AlaifGame.new, (game) async {
    final callout = ComboCallout(text: 'three in a row');
    await game.add(callout);
    game.update(0);
    expect(callout.position.x, game.size.x / 2);
    expect(callout.position.y, 150);
    expect(callout.anchor, Anchor.center);

    game.update(AlaifMotion.comboFlashMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<ComboCallout>(), isEmpty);
  });
}
