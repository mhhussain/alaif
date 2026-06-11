import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';

/// One half of a sliced glyph card, clipped from the full composite texture
/// along the swipe's cut line, tumbling away.
///
/// Removed when it falls past [removeBelowY] OR after
/// [AlaifMotion.cutHalfTumbleMs], whichever comes first.
class SlicedHalf extends PositionComponent {
  SlicedHalf({
    required ui.Image image,
    required Vector2 startPosition,
    required Vector2 velocity,
    required this.topHalf,
    required this.removeBelowY,
    Vector2? displaySize,
    Vector2? cutCenter,
    Vector2? cutDirection,
  })  : _image = image,
        _velocity = velocity.clone() {
    size = displaySize?.clone() ??
        Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = startPosition.clone();

    // Default cut: horizontal line through the component's center, matching
    // a plain top/bottom split when no swipe geometry is given.
    _cutCenter = cutCenter?.clone() ?? Vector2(size.x / 2, size.y / 2);
    final dir = cutDirection?.clone() ?? Vector2(1, 0);
    _cutDirection = dir.length2 > 0 ? (dir..normalize()) : Vector2(1, 0);
  }

  static const gravity = 900.0;
  static const spin = 3.0;

  /// How far the half-plane clip quad extends beyond the component's bounds,
  /// as a multiple of (size.x + size.y), so it always fully covers [size]
  /// regardless of where [cutCenter] sits within it.
  static const _clipExtentFactor = 4.0;

  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;
  late final Vector2 _cutCenter;
  late final Vector2 _cutDirection;
  double _ageMs = 0;

  /// Current tumble velocity (px/s). Exposed for testing the perpendicular
  /// separation of the two halves.
  Vector2 get velocity => _velocity;

  /// Point (in local component coordinates) the cut line passes through.
  Vector2 get cutCenter => _cutCenter;

  /// Unit vector along the cut line that produced this half.
  Vector2 get cutDirection => _cutDirection;

  @override
  void update(double dt) {
    _ageMs += dt * 1000;
    _velocity.y += gravity * dt;
    position += _velocity * dt;
    angle += (topHalf ? -spin : spin) * dt;
    if (position.y > removeBelowY || _ageMs >= AlaifMotion.cutHalfTumbleMs) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final clip = halfPlanePath(
      size: size,
      cutCenter: _cutCenter,
      cutDirection: _cutDirection,
      keepPositiveSide: topHalf,
    );
    canvas.save();
    canvas.clipPath(clip);
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint(),
    );
    canvas.restore();
  }

  /// Builds a `Path` covering one half-plane of an (effectively infinite)
  /// line through [cutCenter] with direction [cutDirection] (need not be
  /// normalized; will be normalized internally — a zero-length direction
  /// falls back to horizontal, i.e. `(1, 0)`).
  ///
  /// The line's normal is `(-cutDirection.y, cutDirection.x)`. A point [p] is
  /// on the "positive" side when `(p - cutCenter) dot normal >= 0`.
  /// [keepPositiveSide] selects which side the returned path covers.
  ///
  /// The path is a quad extended far beyond [size] in both directions along
  /// the line and the chosen normal direction, so clipping with it against a
  /// canvas of [size] always yields exactly the intended half.
  static ui.Path halfPlanePath({
    required Vector2 size,
    required Vector2 cutCenter,
    required Vector2 cutDirection,
    required bool keepPositiveSide,
  }) {
    final dir = cutDirection.length2 > 0
        ? (cutDirection.clone()..normalize())
        : Vector2(1, 0);
    final normal = Vector2(-dir.y, dir.x);
    final extent = (size.x + size.y) * _clipExtentFactor;
    final normalSign = keepPositiveSide ? 1.0 : -1.0;

    final p1 = cutCenter - dir * extent;
    final p2 = cutCenter + dir * extent;
    final p3 = p2 + normal * (extent * normalSign);
    final p4 = p1 + normal * (extent * normalSign);

    return ui.Path()
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..lineTo(p4.x, p4.y)
      ..close();
  }
}
