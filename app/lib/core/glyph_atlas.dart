import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to textures at load.
///
/// Ink & Paper: glyphs render in ArefRuqaa at [AlaifGlyph.renderFontSize]
/// with the vertical ink gradient [AlaifGradients.glyph] and a soft baked
/// drop shadow, padded by [AlaifGlyph.texturePadding] so nothing clips.
class GlyphAtlas {
  static const letters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
    'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
    'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  final Map<String, ui.Image> _images = {};

  ui.Image imageFor(String letter) {
    final image = _images[letter];
    if (image == null) {
      throw StateError('GlyphAtlas.load() must complete before imageFor("$letter")');
    }
    return image;
  }

  Future<void> load({
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    if (_images.isNotEmpty) return; // idempotent — images are native resources
    for (final letter in letters) {
      _images[letter] =
          await renderGlyph(letter, fontSize: fontSize, fontFamily: fontFamily);
    }
  }

  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const pad = AlaifGlyph.texturePadding;
    // Layout once without paint to measure the true glyph box.
    final measure = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(fontSize: fontSize, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final glyphHeight = math.max(measure.height, fontSize);

    // Pass 1 — soft baked shadow (cheap depth on paper).
    final shadowPaint = Paint()
      ..color = AlaifGlyph.shadowColor
      ..maskFilter =
          const ui.MaskFilter.blur(ui.BlurStyle.normal, AlaifGlyph.shadowBlur);
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          foreground: shadowPaint,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    shadowPainter.paint(
      canvas,
      const Offset(pad, pad + AlaifGlyph.shadowOffsetY),
    );

    // Pass 2 — the ink glyph with its vertical gradient.
    final foreground = Paint()
      ..shader = AlaifGradients.glyph.createShader(
        Rect.fromLTWH(pad, pad, math.max(measure.width, 1), glyphHeight),
      );
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          foreground: foreground,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.paint(canvas, const Offset(pad, pad));

    final width = math.max(1, (painter.width + pad * 2).ceil());
    final height = math.max(1, (painter.height + pad * 2).ceil());
    return recorder.endRecording().toImage(width, height);
  }
}
