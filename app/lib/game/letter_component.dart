import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
  }) : _image = image {
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

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
    canvas.drawImage(_image, ui.Offset.zero, ui.Paint());
  }
}
