import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spawn size tokens match the larger device-review-1 spawn sizes', () {
    expect(AlaifGlyph.spawnSizeMin, 196.0);
    expect(AlaifGlyph.spawnSizeMax, 332.0);
    expect(AlaifGlyph.spawnSizeMax, greaterThan(AlaifGlyph.spawnSizeMin));
  });

  test('AlaifCard exposes paper-carrier-card tokens', () {
    // Card fill is a brighter paper than the canvas background, so the card
    // reads as a distinct surface.
    expect(AlaifCard.color, isA<Color>());
    expect(AlaifCard.color, isNot(AlaifColors.paper));

    // Edge hairline reuses the shared hairline ink tone.
    expect(AlaifCard.edgeColor, AlaifColors.hairline);

    // Card side = glyph max extent (width or height of the rendered glyph,
    // including its own texture padding) * this factor. > 1 so the card is
    // larger than the bare glyph).
    expect(AlaifCard.paddingFactor, greaterThan(1.0));

    // Deckled-edge wobble amplitude, in texture pixels.
    expect(AlaifCard.deckleAmplitude, greaterThan(0));

    // Corner radius for the card's rounded-rect base shape.
    expect(AlaifCard.cornerRadius, greaterThan(0));

    // Baked shadow values (reuses the same shape as AlaifGlyph's glyph
    // shadow, but for the card itself).
    expect(AlaifCard.shadowColor, isA<Color>());
    expect(AlaifCard.shadowBlur, greaterThan(0));
    expect(AlaifCard.shadowOffsetY, greaterThan(0));

    // Hit-circle radius factor: the inscribed-circle radius of the card is
    // (side / 2) * hitRadiusFactor, slightly generous for forgiving slicing.
    expect(AlaifCard.hitRadiusFactor, greaterThan(0));
    expect(AlaifCard.hitRadiusFactor, lessThanOrEqualTo(1.0));
  });
}
