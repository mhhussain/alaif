import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token palette matches the Ink & Paper spec', () {
    expect(AlaifColors.paper, const Color(0xFFEDE7D8));
    expect(AlaifColors.ink, const Color(0xFF1B1712));
    expect(AlaifColors.seal, const Color(0xFFB23A2B));
    expect(AlaifColors.goldDust, const Color(0xFFC9A24B));
    expect(AlaifColors.bladeInk, const Color(0xE61B1712));
  });

  test('motion tokens carry the M3 tuning values', () {
    expect(AlaifMotion.bladeRetentionMs, 110);
    expect(AlaifMotion.cutInkParticles, 14);
    expect(AlaifMotion.comboFlashMs, 600);
    expect(AlaifGlyph.renderFontSize, 220.0);
    expect(AlaifGlyph.texturePadding, 24.0);
  });

  test('buildAlaifTheme paints paper surfaces and ink primaries', () {
    final theme = buildAlaifTheme();
    expect(theme.scaffoldBackgroundColor, AlaifColors.paper);
    expect(theme.colorScheme.primary, AlaifColors.ink);
    expect(theme.colorScheme.secondary, AlaifColors.seal);
    expect(theme.useMaterial3, isTrue);
  });
}
