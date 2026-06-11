import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to composite paper-card
/// textures at load.
///
/// Ink & Paper, device review 1 (decision 3): each letter is baked onto a
/// square "carrier card" — a deckled-edge warm-paper rounded rect with a
/// baked soft shadow and hairline border — with the glyph (Katibeh, two-pass
/// shadow + vertical ink gradient) centered on top. The composite texture is
/// square; its side is the card side, exposed via [cardSizeFor]. Hit circle
/// and cut geometry are derived from this known square geometry by
/// [LetterComponent] and [SlicedHalf] — no pixel scanning.
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

  /// The square carrier card's side length, in texture pixels — equal to
  /// both `imageFor(letter).width` and `imageFor(letter).height`.
  double cardSizeFor(String letter) => imageFor(letter).width.toDouble();

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

  /// Renders [letter] as a composite paper-card texture: deckled card (with
  /// baked shadow + hairline border) first, then the two-pass glyph
  /// (shadow + ink gradient) centered on top. The result is square.
  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    const pad = AlaifGlyph.texturePadding;

    // Layout once without paint to measure the true glyph box.
    final measure = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(fontSize: fontSize, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final glyphHeight = math.max(measure.height, fontSize).toDouble();
    final glyphWidth = math.max(measure.width, 1).toDouble();

    // The bare glyph "box" (glyph + texture padding on all sides), as in the
    // pre-card atlas. The card is this box's longest edge, scaled up.
    final glyphBoxWidth = glyphWidth + pad * 2;
    final glyphBoxHeight = glyphHeight + pad * 2;
    final glyphMaxExtent = math.max(glyphBoxWidth, glyphBoxHeight);

    // Card side, rounded up to a whole pixel so the texture has no
    // fractional-pixel edge.
    final cardSide = (glyphMaxExtent * AlaifCard.paddingFactor).ceil().toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // --- Carrier card ---------------------------------------------------
    final cardPath = _cardPath(letter, cardSide);

    // Baked shadow under the card.
    canvas.drawPath(
      cardPath.shift(const Offset(0, AlaifCard.shadowOffsetY)),
      Paint()
        ..color = AlaifCard.shadowColor
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, AlaifCard.shadowBlur),
    );

    // Paper fill.
    canvas.drawPath(cardPath, Paint()..color = AlaifCard.color);

    // Hairline edge.
    canvas.drawPath(
      cardPath,
      Paint()
        ..color = AlaifCard.edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // --- Glyph, centered on the card -------------------------------------
    final glyphOriginX = (cardSide - glyphWidth) / 2;
    final glyphOriginY = (cardSide - glyphHeight) / 2;

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
      Offset(glyphOriginX, glyphOriginY + AlaifGlyph.shadowOffsetY),
    );

    // Pass 2 — the ink glyph with its vertical gradient.
    final foreground = Paint()
      ..shader = AlaifGradients.glyph.createShader(
        Rect.fromLTWH(glyphOriginX, glyphOriginY, glyphWidth, glyphHeight),
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
    painter.paint(canvas, Offset(glyphOriginX, glyphOriginY));

    final side = math.max(1, cardSide.ceil());
    return recorder.endRecording().toImage(side, side);
  }

  /// Builds the deckled-edge rounded-rect `Path` for a card of side
  /// [cardSide], seeded deterministically from [letter]'s position in
  /// [letters] so the wobble is stable across loads (and identical renders
  /// of the same letter produce byte-identical images).
  static ui.Path _cardPath(String letter, double cardSide) {
    final seed = letters.indexOf(letter);
    final random = math.Random(seed >= 0 ? seed : letter.hashCode);

    const segments = AlaifCard.deckleSegmentsPerEdge;
    const amplitude = AlaifCard.deckleAmplitude;
    const radius = AlaifCard.cornerRadius;

    // Base rounded rect, inset so the deckle wobble never exceeds the
    // texture bounds.
    final base = Rect.fromLTWH(
      amplitude,
      amplitude,
      cardSide - amplitude * 2,
      cardSide - amplitude * 2,
    );

    final path = ui.Path();

    // Walk each edge in `segments` steps, perturbing each interior vertex
    // perpendicular to the edge by a random amount in [-amplitude, amplitude].
    // Corners (the rounded-rect corners) are left unperturbed so the
    // rounding reads cleanly.
    final corners = [
      base.topLeft + Offset(radius, 0),
      base.topRight + Offset(-radius, 0),
      base.topRight + Offset(0, radius),
      base.bottomRight + Offset(0, -radius),
      base.bottomRight + Offset(-radius, 0),
      base.bottomLeft + Offset(radius, 0),
      base.bottomLeft + Offset(0, -radius),
      base.topLeft + Offset(0, radius),
    ];

    void deckledEdge(Offset from, Offset to) {
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length == 0) {
        path.lineTo(to.dx, to.dy);
        return;
      }
      // Unit normal (perpendicular to the edge).
      final nx = -dy / length;
      final ny = dx / length;
      for (var i = 1; i < segments; i++) {
        final t = i / segments;
        final px = from.dx + dx * t;
        final py = from.dy + dy * t;
        final wobble = (random.nextDouble() * 2 - 1) * amplitude;
        path.lineTo(px + nx * wobble, py + ny * wobble);
      }
      path.lineTo(to.dx, to.dy);
    }

    // Start at the first corner, draw deckled edges between corner pairs,
    // and arc around each rounded corner.
    path.moveTo(corners[0].dx, corners[0].dy);
    deckledEdge(corners[0], corners[1]);
    path.arcToPoint(corners[2], radius: const Radius.circular(radius));
    deckledEdge(corners[2], corners[3]);
    path.arcToPoint(corners[4], radius: const Radius.circular(radius));
    deckledEdge(corners[4], corners[5]);
    path.arcToPoint(corners[6], radius: const Radius.circular(radius));
    deckledEdge(corners[6], corners[7]);
    path.arcToPoint(corners[0], radius: const Radius.circular(radius));
    path.close();

    return path;
  }
}
