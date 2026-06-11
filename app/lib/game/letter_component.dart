import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
    double targetSize = AlaifGlyph.spawnSizeMax,
  }) : _image = image {
    final longest = math.max(image.width, image.height).toDouble();
    final scale = targetSize / longest;
    size = Vector2(image.width * scale, image.height * scale);
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  /// Set the instant this letter is sliced, before `removeFromParent()` takes
  /// effect (which Flame defers to the next update tick). Prevents a single
  /// swipe's later drag-update segments from re-slicing the same letter.
  bool sliced = false;

  ui.Image get image => _image;
  /// Circular hit approximation using half-width; tall glyphs have a smaller vertical hit extent by design.
  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
    angle += 0.5 * dt; // gentle tumble
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint(),
    );
  }
}
