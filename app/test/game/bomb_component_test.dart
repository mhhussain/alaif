import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BombComponent staticBomb() => BombComponent(
        motion: ArcMotion(
          start: Vector2(100, 100),
          velocity: Vector2.zero(),
          gravity: 0,
        ),
      );

  test('bomb ring is seal red with a 2px stroke', () {
    expect(BombComponent.ringColor, AlaifColors.seal);
    expect(BombComponent.ringStrokeWidth, 2.0);
  });

  test('bomb spark is gold dust', () {
    expect(BombComponent.sparkColor, AlaifColors.goldDust);
  });

  test('bomb keeps its motion and hit radius behaviour', () {
    final bomb = staticBomb();
    expect(bomb.hitRadius, 40);
    bomb.update(1.0);
    expect(bomb.position, Vector2(100, 100));
  });

  test('bomb render does not throw', () {
    final bomb = staticBomb();
    bomb.update(0.123); // advance the spark flicker phase
    final recorder = ui.PictureRecorder();
    bomb.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
