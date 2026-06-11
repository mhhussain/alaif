import 'package:alaif/core/glyph_atlas.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a single glyph card to a non-empty square image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
    // The carrier card is square.
    expect(image.width, image.height);
  });

  test('glyph card includes the spec padding plus card padding factor',
      () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    // Card side = glyph box (>= 2*texturePadding) * paddingFactor, so the
    // composite image must clearly exceed the bare texture padding alone.
    expect(image.width,
        greaterThan((AlaifGlyph.texturePadding * 2 * AlaifCard.paddingFactor).toInt()));
  });

  test('glyph pixels are ink, not the old gold gradient', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final data = (await image.toByteData())!; // rawRgba: r,g,b,a per pixel
    var inkFound = false;
    var goldFound = false;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      final a = data.getUint8(i + 3);
      if (a > 200 && r < 0x40 && g < 0x40) inkFound = true;
      // Saturated gold (~0xFFFFD97A: r=0xFF, g=0xD9, b=0x7A) has a low blue
      // channel, unlike the warm paper carrier-card fill (~0xFFF7F1E3:
      // r=0xF7, g=0xF1, b=0xE3) which is high in blue. The b < 0x80 check
      // keeps this heuristic from false-flagging the paper as gold.
      if (a > 200 && r > 0xE0 && g > 0x90 && b < 0x80) goldFound = true;
    }
    expect(inkFound, isTrue, reason: 'expected near-black ink pixels');
    expect(goldFound, isFalse, reason: 'old gold gradient should be gone');
  });

  test('glyph card includes the carrier-card paper fill color', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final data = (await image.toByteData())!;
    var cardFound = false;
    const cardColor = AlaifCard.color;
    final cardR = (cardColor.r * 255).round();
    final cardG = (cardColor.g * 255).round();
    final cardB = (cardColor.b * 255).round();
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      final a = data.getUint8(i + 3);
      if (a > 200 &&
          (r - cardR).abs() <= 2 &&
          (g - cardG).abs() <= 2 &&
          (b - cardB).abs() <= 2) {
        cardFound = true;
        break;
      }
    }
    expect(cardFound, isTrue,
        reason: 'expected AlaifCard.color paper-fill pixels somewhere on the card');
  });

  test('atlas exposes all 28 letters', () {
    expect(GlyphAtlas.letters.length, 28);
    expect(GlyphAtlas.letters.toSet().length, 28); // no duplicates
  });

  test('load makes every letter available', () async {
    final atlas = GlyphAtlas();
    await atlas.load();
    for (final letter in GlyphAtlas.letters) {
      expect(atlas.imageFor(letter).width, greaterThan(0));
    }
  });

  test('imageFor throws before load', () {
    expect(() => GlyphAtlas().imageFor('ب'), throwsStateError);
  });

  test('cardSizeFor returns the square card side for every letter after load',
      () async {
    final atlas = GlyphAtlas();
    await atlas.load();
    for (final letter in GlyphAtlas.letters) {
      final side = atlas.cardSizeFor(letter);
      expect(side, greaterThan(0));
      expect(side, atlas.imageFor(letter).width.toDouble());
      expect(side, atlas.imageFor(letter).height.toDouble());
    }
  });

  test('cardSizeFor throws before load', () {
    expect(() => GlyphAtlas().cardSizeFor('ب'), throwsStateError);
  });

  test('renderGlyph is deterministic for the same letter (stable deckle seed)',
      () async {
    final a = await GlyphAtlas.renderGlyph('ب');
    final b = await GlyphAtlas.renderGlyph('ب');
    expect(a.width, b.width);
    expect(a.height, b.height);
    final dataA = (await a.toByteData())!;
    final dataB = (await b.toByteData())!;
    expect(dataA.buffer.asUint8List(), dataB.buffer.asUint8List());
  });
}
