import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to textures at load.
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

  Future<void> load({double fontSize = 120, String? fontFamily}) async {
    for (final letter in letters) {
      _images[letter] =
          await renderGlyph(letter, fontSize: fontSize, fontFamily: fontFamily);
    }
  }

  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = 120,
    String? fontFamily,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final foreground = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, fontSize),
        const [Color(0xFFFFD97A), Color(0xFFFF9D3D)],
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
    painter.paint(canvas, Offset.zero);
    final width = math.max(1, painter.width.ceil());
    final height = math.max(1, painter.height.ceil());
    return recorder.endRecording().toImage(width, height);
  }
}
