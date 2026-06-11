import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

/// Maximum magnitude of the per-spawn random "toss" rotation (radians),
/// applied once at construction when a [Random] source is supplied.
const double _maxSpawnRotation = 0.12;

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
    double targetSize = AlaifGlyph.spawnSizeMax,
    math.Random? random,
  }) : _image = image {
    final longest = math.max(image.width, image.height).toDouble();
    final scale = targetSize / longest;
    size = Vector2(image.width * scale, image.height * scale);
    anchor = Anchor.center;
    position = motion.positionAt(0);

    // Hit circle is the inscribed circle of the (square) carrier card,
    // scaled slightly by AlaifCard.hitRadiusFactor for a forgiving hit area.
    // For non-square textures (e.g. test fixtures), use the longer scaled
    // edge so the hit area still comfortably covers the texture.
    _hitRadius = math.max(size.x, size.y) / 2 * AlaifCard.hitRadiusFactor;

    // Per-spawn "toss": a small fixed rotation in [-0.12, 0.12] rad, applied
    // once. Omitted (angle stays 0) when no Random source is supplied, so
    // existing callers that don't care about rotation are unaffected.
    if (random != null) {
      angle = (random.nextDouble() * 2 - 1) * _maxSpawnRotation;
    }
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;
  late final double _hitRadius;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  /// Set the instant this letter is sliced, before `removeFromParent()` takes
  /// effect (which Flame defers to the next update tick). Prevents a single
  /// swipe's later drag-update segments from re-slicing the same letter.
  bool sliced = false;

  ui.Image get image => _image;

  /// Circular hit approximation centered on the component, sized from the
  /// scaled carrier-card geometry (see [AlaifCard.hitRadiusFactor]).
  double get hitRadius => _hitRadius;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
    angle += 0.5 * dt; // gentle tumble (in addition to the fixed spawn tilt)
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
