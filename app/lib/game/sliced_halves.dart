import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// One half of a sliced glyph, clipped from the full texture, tumbling away.
class SlicedHalf extends PositionComponent {
  SlicedHalf({
    required ui.Image image,
    required Vector2 startPosition,
    required Vector2 velocity,
    required this.topHalf,
    required this.removeBelowY,
  })  : _image = image,
        _velocity = velocity.clone() {
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = startPosition.clone();
  }

  static const gravity = 900.0;
  static const spin = 3.0;

  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;

  @override
  void update(double dt) {
    _velocity.y += gravity * dt;
    position += _velocity * dt;
    angle += (topHalf ? -spin : spin) * dt;
    if (position.y > removeBelowY) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final clip = topHalf
        ? ui.Rect.fromLTWH(0, 0, size.x, size.y / 2)
        : ui.Rect.fromLTWH(0, size.y / 2, size.x, size.y / 2);
    canvas.save();
    canvas.clipRect(clip);
    canvas.drawImage(_image, ui.Offset.zero, ui.Paint());
    canvas.restore();
  }
}
