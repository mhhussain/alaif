import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

/// Ink & Paper bomb: dark radial ink sphere, 2px seal danger ring, a short
/// fuse with a flickering gold-dust spark, and a paper "!" cut into the ink.
class BombComponent extends PositionComponent {
  BombComponent({required this.motion}) {
    size = Vector2.all(80);
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  static const ringColor = AlaifColors.seal;
  static const ringStrokeWidth = 2.0;
  static const sparkColor = AlaifColors.goldDust;

  /// "!" laid out once and reused by every bomb (no per-frame text layout).
  static final TextPainter _exclaim = TextPainter(
    text: const TextSpan(
      text: '!',
      style: TextStyle(
        fontFamily: AlaifFonts.ui,
        fontSize: 30,
        fontWeight: FontWeight.w500,
        color: AlaifColors.onInk,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final ArcMotion motion;
  double _age = 0;
  bool entered = false;

  /// Circular hit approximation using half-width; tall glyphs have a smaller vertical hit extent by design.
  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - ringStrokeWidth;

    // Ink sphere with a faint top-light so it reads as a sphere, not a dot.
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.3, -radius * 0.35),
          radius * 1.6,
          const [AlaifColors.glyphTop, AlaifColors.ink],
        ),
    );

    // Seal danger ring.
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()
        ..color = ringColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = ringStrokeWidth,
    );

    // Short fuse line out the top-right + flickering gold-dust spark.
    final fuseStart = center.translate(radius * 0.5, -radius * 0.75);
    final fuseEnd = center.translate(radius * 0.8, -radius * 1.15);
    canvas.drawLine(
      fuseStart,
      fuseEnd,
      ui.Paint()
        ..color = AlaifColors.ink
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = ui.StrokeCap.round,
    );
    final flicker = 2.5 + math.sin(_age * 18) * 1.0;
    canvas.drawCircle(fuseEnd, flicker, ui.Paint()..color = sparkColor);

    // Paper "!" cut into the ink.
    _exclaim.paint(
      canvas,
      center.translate(-_exclaim.width / 2, -_exclaim.height / 2),
    );
  }
}
