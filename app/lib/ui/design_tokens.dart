// design_tokens.dart
//
// Alaif — "Ink & Paper" design tokens (v1).
// Generated from the 2026-06 visual design session. Single source of truth for
// the Flutter shell (overlays/menus) AND the Flame layer (glyphs, blade, HUD,
// bombs, particles) so the two worlds read as one product.
//
// Suggested path in repo: app/lib/ui/design_tokens.dart
//
// Direction: black calligraphy on warm paper. Vermillion seal as the brand
// mark. Cuts throw ink; combos sparkle gold. Spectral for UI text, Aref Ruqaa
// for the sliced hero glyphs. Everything below is `const` and offline-safe.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// COLOR
// ---------------------------------------------------------------------------
abstract class AlaifColors {
  // Surfaces — the game now runs on PAPER, not the old dark purple.
  static const paper = Color(0xFFEDE7D8); // primary background / game canvas
  static const paperDeep = Color(0xFFE4DCC8); // vignette / gradient floor
  static const surface = Color(0xFFEDE7D8); // overlay panels (same paper)
  static const scrim = Color(0xC7EDE7D8); // 0.78 paper wash over paused game

  // Ink — text, glyphs, blade, bombs.
  static const ink = Color(0xFF1B1712); // primary: glyphs, headings, buttons
  static const inkSoft = Color(0xFF2A251E); // body text
  static const inkMuted = Color(0xFF867C6C); // labels, captions, secondary
  static const hairline = Color(0x241B1712); // 0.14 ink — dividers, borders
  static const onInk = Color(0xFFEDE7D8); // text/icons on ink-filled buttons

  // Accents.
  static const seal = Color(0xFFB23A2B); // brand mark, combo, danger
  static const sealDark = Color(0xFF8E2C20); // pressed / shadow
  static const gold = Color(0xFFA8842F); // score-up highlight
  static const goldDust = Color(0xFFC9A24B); // combo particle glint

  // Glyph fill — a near-black ink with a faint vertical gradient so a big
  // sliced letter reads with dimension (top lifts, bottom pools).
  static const glyphTop = Color(0xFF2C2720);
  static const glyphBottom = Color(0xFF14110B);

  // Blade trail — dark ink brush stroke (NOT white-hot; the ground is light).
  static const bladeInk = Color(0xE61B1712); // 0.9 ink, core of the stroke
  static const bladeEdge = Color(0x001B1712); // transparent feathered edge

  // Semantic.
  static const scoreUp = gold;
  static const lifeLost = seal;
  static const combo = seal;
  static const gameOver = ink;
  static const bombDanger = seal;
}

abstract class AlaifGradients {
  /// Vertical ink gradient painted into each cached glyph texture.
  static const glyph = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AlaifColors.glyphTop, AlaifColors.glyphBottom],
  );

  /// Subtle paper background (radial would be nicer; this is the cheap fallback).
  static const paper = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AlaifColors.paper, AlaifColors.paperDeep],
  );

  /// Blade trail gradient along the stroke (tail → head).
  static const blade = LinearGradient(
    colors: [AlaifColors.bladeEdge, AlaifColors.bladeInk, AlaifColors.bladeEdge],
    stops: [0.0, 0.6, 1.0],
  );
}

// ---------------------------------------------------------------------------
// SPACING  (4-based scale)
// ---------------------------------------------------------------------------
abstract class AlaifSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Standard screen inset for overlay content (left/right).
  static const screenPad = 38.0;
}

abstract class AlaifRadii {
  static const none = 0.0;
  static const sm = 4.0; // buttons, panels — Ink & Paper stays near-square
  static const md = 8.0;
  static const lg = 12.0;
  static const pill = 999.0;
}

// ---------------------------------------------------------------------------
// TYPOGRAPHY
// Families must be declared in pubspec.yaml (see visual-design-spec.md).
// ---------------------------------------------------------------------------
abstract class AlaifFonts {
  static const ui = 'Spectral'; // Latin UI serif
  static const arabic = 'ArefRuqaa'; // calligraphic hero glyph + Arabic accents
}

abstract class AlaifType {
  static const _tnum = <FontFeature>[FontFeature.tabularFigures()];

  /// Menu wordmark "Alaif".
  static const titleDisplay = TextStyle(
    fontFamily: AlaifFonts.ui, fontStyle: FontStyle.italic,
    fontSize: 64, fontWeight: FontWeight.w400, height: 0.95,
    letterSpacing: -0.5, color: AlaifColors.ink,
  );

  /// Arabic subtitle (الألِف) / Arabic accents.
  static const titleArabic = TextStyle(
    fontFamily: AlaifFonts.arabic, fontSize: 22,
    fontWeight: FontWeight.w400, color: AlaifColors.seal,
  );

  /// Overlay headings — "How to play", "Settings", "Paused".
  static const heading = TextStyle(
    fontFamily: AlaifFonts.ui, fontStyle: FontStyle.italic,
    fontSize: 32, fontWeight: FontWeight.w500, color: AlaifColors.ink,
  );

  /// Sub-heading inside how-to rows etc.
  static const subheading = TextStyle(
    fontFamily: AlaifFonts.ui, fontStyle: FontStyle.italic,
    fontSize: 19, fontWeight: FontWeight.w500, color: AlaifColors.ink,
  );

  /// Body copy.
  static const body = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 16,
    fontWeight: FontWeight.w400, height: 1.5, color: AlaifColors.inkSoft,
  );
  static const bodyMuted = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 15,
    fontWeight: FontWeight.w400, height: 1.5, color: AlaifColors.inkMuted,
  );

  /// In-game HUD score.
  static const scoreHud = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 40, fontWeight: FontWeight.w500,
    height: 1.0, color: AlaifColors.ink, fontFeatures: _tnum,
  );

  /// Final / paused score.
  static const scoreLarge = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 76, fontWeight: FontWeight.w400,
    height: 0.95, color: AlaifColors.ink, fontFeatures: _tnum,
  );

  /// All-caps tracked label — "BEST", "SCORE", "CURRENT SCORE".
  /// Caller uppercases the string; letterSpacing bakes the tracking.
  static const label = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 12, fontWeight: FontWeight.w500,
    letterSpacing: 2.6, color: AlaifColors.inkMuted,
  );

  /// Combo callout — "four in a row", "×4".
  static const combo = TextStyle(
    fontFamily: AlaifFonts.ui, fontStyle: FontStyle.italic,
    fontSize: 20, fontWeight: FontWeight.w500, color: AlaifColors.combo,
  );

  /// Primary (ink-filled) button label.
  static const button = TextStyle(
    fontFamily: AlaifFonts.ui, fontStyle: FontStyle.italic,
    fontSize: 19, fontWeight: FontWeight.w500,
    letterSpacing: 1.1, color: AlaifColors.onInk,
  );

  /// Ghost / secondary button label.
  static const buttonGhost = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 16,
    fontWeight: FontWeight.w400, color: AlaifColors.ink,
  );

  static const caption = TextStyle(
    fontFamily: AlaifFonts.ui, fontSize: 13,
    fontWeight: FontWeight.w400, color: AlaifColors.inkMuted,
  );
}

// ---------------------------------------------------------------------------
// MOTION / JUICE  (tuning surface for M3)
// All values are starting points — profile on device and adjust.
// ---------------------------------------------------------------------------
abstract class AlaifMotion {
  // Blade trail (BladeTrail component).
  static const bladeRetentionMs = 110; // how long a trail point lives
  static const bladeWidth = 7.0; // head thickness
  static const bladeMinWidth = 1.5; // tail thickness (tapers to this)

  // Cut feedback — ink splatter when a letter is sliced.
  static const cutInkParticles = 14;
  static const cutParticleSpeedMin = 120.0; // px/s
  static const cutParticleSpeedMax = 360.0;
  static const cutParticleLifeMs = 520;
  static const cutHalfTumbleMs = 900; // sliced halves spin off-screen

  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade

  // Score / life pops.
  static const scorePopMs = 220;
  static const lifeLostFlashMs = 280;

  // Standard overlay transition.
  static const overlayFadeMs = 220;
  static const overlayCurve = Curves.easeOutCubic;
}

// ---------------------------------------------------------------------------
// GLYPH ATLAS CONFIG  (GlyphAtlas — pre-rendered letter textures)
// ---------------------------------------------------------------------------
abstract class AlaifGlyph {
  /// Font size used when pre-rendering each letter to a ui.Image texture.
  /// Render large for crispness; scale down per-spawn in the component.
  static const renderFontSize = 220.0;

  /// Texture padding so the gradient + faint shadow aren't clipped.
  static const texturePadding = 24.0;

  /// On-screen letter size range (diameter-ish) at spawn.
  static const spawnSizeMin = 96.0;
  static const spawnSizeMax = 132.0;

  /// Soft drop shadow baked into the texture (cheap depth on paper).
  static const shadowBlur = 3.0;
  static const shadowOffsetY = 2.0;
  static const shadowColor = Color(0x2E1B1712); // ~0.18 ink
}
