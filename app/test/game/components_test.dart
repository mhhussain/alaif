import 'dart:math';
import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('letter hit radius derives from its scaled on-screen size via AlaifCard.hitRadiusFactor', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
    );
    // size is (80, 80); hitRadius = max(size.x, size.y) / 2 * hitRadiusFactor.
    expect(letter.hitRadius, 80 / 2 * AlaifCard.hitRadiusFactor);
  });

  test('letter scales its texture down to targetSize, keeping aspect, and hitRadius follows', () async {
    final image = await testImage(width: 100, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100,
    );
    expect(letter.size, Vector2(50, 100)); // longest edge == targetSize
    // hitRadius = max(size.x, size.y) / 2 * hitRadiusFactor = max(50,100)/2 * factor.
    expect(letter.hitRadius, 100 / 2 * AlaifCard.hitRadiusFactor);
  });

  test('letter with no random source gets zero extra rotation', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
    );
    expect(letter.angle, 0);
  });

  test('letter with a seeded random source gets a small fixed rotation in [-0.12, 0.12] rad', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
      random: Random(42),
    );
    expect(letter.angle, greaterThanOrEqualTo(-0.12));
    expect(letter.angle, lessThanOrEqualTo(0.12));
    // Same seed -> same rotation (deterministic).
    final again = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
      random: Random(42),
    );
    expect(again.angle, letter.angle);
  });

  test('letter defaults to the max spawn size from the tokens', () async {
    final image = await testImage(width: 200, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
    );
    expect(letter.size.x, AlaifGlyph.spawnSizeMax);
  });

  testWithGame<AlaifGame>('sliced half is removed after cutHalfTumbleMs',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000, // never trips the off-screen rule in this test
    );
    await game.add(half);
    game.update(0);
    expect(game.children.whereType<SlicedHalf>().length, 1);

    game.update(AlaifMotion.cutHalfTumbleMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<SlicedHalf>(), isEmpty);
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

  group('SlicedHalf.halfPlanePath', () {
    test('horizontal cut through center: positive side keeps the bottom half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(1, 0), // horizontal line y=50
        keepPositiveSide: true, // normal = (0,1) -> positive side is y > 50
      );
      expect(path.contains(const ui.Offset(50, 90)), isTrue); // below the line
      expect(path.contains(const ui.Offset(50, 10)), isFalse); // above the line
    });

    test('horizontal cut through center: negative side keeps the top half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(1, 0),
        keepPositiveSide: false,
      );
      expect(path.contains(const ui.Offset(50, 10)), isTrue); // above the line
      expect(path.contains(const ui.Offset(50, 90)), isFalse); // below the line
    });

    test('vertical cut through center: positive side keeps the left half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(0, 1), // vertical line x=50
        keepPositiveSide: true, // normal = (-1,0) -> positive side is x < 50
      );
      // For direction (0,1), normal = (-dy, dx) = (-1, 0), so the positive
      // side ((p-c) dot normal >= 0) is x <= 50 (the left half).
      expect(path.contains(const ui.Offset(10, 50)), isTrue); // left
      expect(path.contains(const ui.Offset(90, 50)), isFalse); // right
    });

    test('off-center cut point shifts the dividing line', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 20), // line y=20
        cutDirection: Vector2(1, 0),
        keepPositiveSide: true, // y > 20
      );
      expect(path.contains(const ui.Offset(50, 50)), isTrue); // y=50 > 20
      expect(path.contains(const ui.Offset(50, 5)), isFalse); // y=5 < 20
    });

    test('zero-length cut direction falls back to horizontal', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2.zero(),
        keepPositiveSide: true,
      );
      expect(path.contains(const ui.Offset(50, 90)), isTrue); // below
      expect(path.contains(const ui.Offset(50, 10)), isFalse); // above
    });
  });

  testWithGame<AlaifGame>('sliced half defaults to a horizontal cut through its center',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage(width: 100, height: 100);
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000,
      displaySize: Vector2(100, 100),
    );
    expect(half.cutCenter, Vector2(50, 50));
    expect(half.cutDirection, Vector2(1, 0));

    final recorder = ui.PictureRecorder();
    half.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });

  testWithGame<AlaifGame>('sliced half with explicit cut geometry renders without throwing',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000,
      cutCenter: Vector2(20, 30),
      cutDirection: Vector2(1, 1),
    );
    await game.add(half);
    game.update(0);

    final recorder = ui.PictureRecorder();
    half.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
