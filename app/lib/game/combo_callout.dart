import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Centered combo line ("three in a row" / "×N"): seal italic, scales up
/// slightly while fading out over [AlaifMotion.comboFlashMs], then removes
/// itself (spec §4.3).
class ComboCallout extends PositionComponent with HasGameReference<AlaifGame> {
  ComboCallout({required this.text}) : super(priority: 95);

  final String text;
  double _ageMs = 0;
  late final TextPainter _painter;
  final ui.Paint _layerPaint = ui.Paint();

  /// Spell out the chains the spec names; bigger chains read as a counter.
  static String comboText(int hits) {
    switch (hits) {
      case 3:
        return 'three in a row';
      case 4:
        return 'four in a row';
      default:
        return '×$hits'; // ×N
    }
  }

  @override
  void onLoad() {
    _painter = TextPainter(
      text: TextSpan(text: text, style: AlaifType.combo),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_painter.width, _painter.height);
    anchor = Anchor.center;
    position = Vector2(game.size.x / 2, 150);
  }

  @override
  void update(double dt) {
    _ageMs += dt * 1000;
    if (_ageMs >= AlaifMotion.comboFlashMs) {
      removeFromParent();
      return;
    }
    final t = _ageMs / AlaifMotion.comboFlashMs;
    scale = Vector2.all(1 + 0.15 * t);
  }

  @override
  void render(ui.Canvas canvas) {
    final t = (_ageMs / AlaifMotion.comboFlashMs).clamp(0.0, 1.0);
    final bounds = ui.Rect.fromLTWH(0, 0, size.x, size.y).inflate(8);
    _layerPaint.color = const ui.Color(0xFF000000).withValues(alpha: 1 - t);
    canvas.saveLayer(bounds, _layerPaint);
    _painter.paint(canvas, ui.Offset.zero);
    canvas.restore();
  }
}
