import 'dart:ui' as ui;

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/paper_background.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lattice tile renders to a square non-empty image', () async {
    final tile = await PaperBackground.buildLatticeTile();
    expect(tile.width, PaperBackground.tileSize);
    expect(tile.height, PaperBackground.tileSize);
  });

  testWithGame<AlaifGame>('game background is paper and PaperBackground is mounted',
      AlaifGame.new, (game) async {
    expect(game.backgroundColor(), AlaifColors.paper);
    final bg = game.children.whereType<PaperBackground>().single;
    expect(bg.hasLattice, isTrue);
    expect(bg.size, game.size);
    expect(bg.priority, lessThan(0)); // renders under everything
  });

  testWithGame<AlaifGame>('PaperBackground render does not throw',
      AlaifGame.new, (game) async {
    final bg = game.children.whereType<PaperBackground>().single;
    final recorder = ui.PictureRecorder();
    bg.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
