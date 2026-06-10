import 'package:alaif/core/glyph_atlas.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a single glyph to a non-empty image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  });

  test('glyph texture includes the spec padding on both axes', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    // Texture = glyph box + 2 * texturePadding; the glyph itself is at least
    // a few px wide, so the image must clearly exceed the padding alone.
    expect(image.width, greaterThan((AlaifGlyph.texturePadding * 2).toInt()));
    expect(image.height, greaterThan((AlaifGlyph.texturePadding * 2).toInt()));
  });

  test('glyph pixels are ink, not the old gold gradient', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final data = (await image.toByteData())!; // rawRgba: r,g,b,a per pixel
    var inkFound = false;
    var goldFound = false;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final a = data.getUint8(i + 3);
      if (a > 200 && r < 0x40 && g < 0x40) inkFound = true;
      if (a > 200 && r > 0xE0 && g > 0x90) goldFound = true; // 0xFFFFD97A-ish
    }
    expect(inkFound, isTrue, reason: 'expected near-black ink pixels');
    expect(goldFound, isFalse, reason: 'old gold gradient should be gone');
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
}
