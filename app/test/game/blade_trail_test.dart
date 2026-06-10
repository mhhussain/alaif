import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/blade_trail.dart';
import 'package:alaif/game/hud.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('startGame installs blade trail and hud once',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<BladeTrail>().length, 1);
    expect(game.children.whereType<Hud>().length, 1);
  });

  testWithGame<AlaifGame>('blade trail covers the full screen', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.size, game.size);
  });

  testWithGame<AlaifGame>('blade trail retains points for bladeRetentionMs',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.buffer.maxAge,
        closeTo(AlaifMotion.bladeRetentionMs / 1000, 1e-9));
  });

  test('stroke width tapers from bladeMinWidth (tail) to bladeWidth (head)', () {
    expect(BladeTrail.strokeWidthFor(1, 1), AlaifMotion.bladeWidth); // lone segment
    expect(BladeTrail.strokeWidthFor(1, 10), AlaifMotion.bladeMinWidth); // tail
    expect(BladeTrail.strokeWidthFor(10, 10), AlaifMotion.bladeWidth); // head
    // Monotonic toward the head.
    expect(BladeTrail.strokeWidthFor(5, 10),
        greaterThan(BladeTrail.strokeWidthFor(2, 10)));
  });
}
