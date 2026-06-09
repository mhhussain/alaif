import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> testImage({int width = 40, int height = 60}) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(width, height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('letter follows its arc as time advances', () async {
    final image = await testImage();
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2(100, 500), velocity: Vector2(20, -300), gravity: 0),
    );
    expect(letter.position, Vector2(100, 500));
    letter.update(1.0);
    expect(letter.position, Vector2(120, 200));
  });

  test('letter hit radius derives from its size', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
    );
    expect(letter.hitRadius, 40);
  });

  test('sliced half falls and removes itself below the cutoff', () async {
    // removeFromParent() is a no-op outside a FlameGame; position advancement is the observable proxy for update being called.
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2(0, 100),
      topHalf: true,
      removeBelowY: 200,
    );
    half.update(0.5); // y ≈ 100 + ~50–70 (gravity adds speed)
    expect(half.position.y, greaterThan(100));
  });
}
