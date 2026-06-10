import 'dart:ui' as ui;

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/hud.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('hud covers the screen and tracks the score text',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    expect(hud.size, game.size);
    expect(hud.scoreText, '0');

    game.scoreState.registerHit(); // +10
    expect(hud.scoreText, '10');
  });

  testWithGame<AlaifGame>('lives dots fill while alive and hollow when lost',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    expect(hud.dotFilled(0), isTrue);
    expect(hud.dotFilled(1), isTrue);
    expect(hud.dotFilled(2), isTrue);

    game.rules.onBombSliced(); // 2 lives left
    expect(hud.dotFilled(0), isTrue);
    expect(hud.dotFilled(1), isTrue);
    expect(hud.dotFilled(2), isFalse);
  });

  testWithGame<AlaifGame>('hud render does not throw', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    final recorder = ui.PictureRecorder();
    hud.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
