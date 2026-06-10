---
title: Design Brief Prompt (UI / Visual Design)
type: prompt
created: 2026-06-09
---

# Design Brief Prompt

A ready-to-paste prompt for a fresh Claude Code session, scoped to design Alaif's UI, color palette, and overall look & feel. Copy everything in the code block below into a new session.

---

```
You are doing UI/visual design work for "Alaif" — a Fruit Ninja–style mobile
game (iOS/Android, portrait only) built with Flutter + Flame, where players
swipe to slice flying Arabic calligraphic letters out of the air. The Arabic
letters are purely decorative game objects (like the fruit in Fruit Ninja) —
there's no language-learning or educational mechanic.

## Repo context (read these first)

- Repo root: /Users/iammoo/code/alaif
- Design/gameplay spec: wiki/alaif-v1-design.md
- Game vision doc: wiki/game-vision.md
- Current Flutter shell overlays (very rough placeholders right now):
  - app/lib/ui/menu_overlay.dart
  - app/lib/ui/game_over_overlay.dart
  - app/lib/ui/pause_overlay.dart
- Main game class (background color, overlay wiring): app/lib/game/alaif_game.dart
- HUD (score/lives text): app/lib/game/hud.dart
- Glyph rendering / current letter gradient: app/lib/core/glyph_atlas.dart

## Current state (so you don't have to reverse-engineer it)

- Background color: dark purple-black, 0xFF120C1D
- Letters are rendered as a gradient from gold to orange: 0xFFFFD97A → 0xFFFF9D3D
- Overlays (menu, game over, pause) are plain Center/Column layouts with
  default Material widgets: stock ElevatedButton, default TextStyle, white text
- HUD is a single plain TextComponent ("Score X   Lives Y") in the top-left
- No custom fonts, no custom theme, no app icon yet — everything is Flutter
  defaults dressed up with one background color and one gradient

This is a solid functional skeleton with zero visual identity. Your job is to
give it one.

## Scope

Design (and specify, in writing — see Deliverables) the full visual language
for v1, covering:

1. **Overall art direction & mood** — what feeling should this game have?
   (e.g. "elegant night-market neon calligraphy", "manuscript/illuminated
   parchment with modern glow", "geometric arabesque tech-noir", etc.)
2. **Color palette** — background(s), letter glyph gradient(s) (can vary by
   letter or be a fixed family), blade/slice trail color & glow, bomb styling
   (color, icon/symbol, danger cues), UI accent colors, semantic colors
   (score up, life lost, combo, game over).
3. **Typography** — pick a calligraphic/decorative Arabic display font from
   Google Fonts for the sliced letters themselves (this is the hero visual
   element — it needs to look beautiful large and read cleanly when split in
   half), plus a complementary UI/Latin font for menus, scores, and body text.
   Note the Google Fonts license (almost all are OFL — confirm and note it)
   and how to bundle it (flutter `google_fonts` package vs. vendoring the
   font file under app/assets/fonts/ for fully-offline builds — this game has
   no network access at runtime, so prefer vendoring).
4. **Screens & overlays**:
   - Main menu (title treatment, play button, best score display)
   - Pause overlay
   - Game over overlay (score, best score, replay/menu actions)
   - Controls/how-to-play overlay (swipe to slice, avoid bombs, combos)
   - In-game HUD (score, lives, combo indicator)
5. **Background** — static or subtle animated/parallax treatment behind the
   gameplay (must stay cheap — see Constraints).
6. **App icon direction** — concept description(s) for the app icon (a single
   stylized letter? a blade slicing a glyph? geometric mark?), suitable for
   iOS/Android adaptive icon treatment.

## Deliverables

Produce a written design spec saved into wiki/ (propose a filename, e.g.
wiki/visual-design-spec.md) containing:

1. **Design tokens** as a ready-to-use Dart file (e.g.
   app/lib/ui/design_tokens.dart or similar — propose the path) defining:
   - Color constants (background, gradients, accents, semantic colors)
   - Spacing scale constants
   - TextStyle constants for each typographic role (title, button, HUD,
     body, score, combo callout, etc.)
   These should be expressed as `const` Dart values usable directly from
   Flutter widgets and Flame components.
2. **Per-screen mockup descriptions** — for each screen/overlay in scope,
   describe the layout, hierarchy, color usage, and key visual details in
   enough detail that another engineer (or you, in a follow-up session) could
   implement it without further design decisions. Plain prose + simple
   ASCII/diagram sketches are fine — no image generation required.
3. **Asset list** — every new asset implied by the spec (fonts to vendor,
   any icon/SVG assets, particle textures if needed, app icon source files),
   with source/attribution notes for anything pulled from Google Fonts or
   elsewhere.
4. **Implementation guidance**:
   - How the design tokens map onto a Flutter `ThemeData` (for the Material
     overlay widgets) so menu/pause/game-over screens pick up consistent
     styling with minimal per-widget overrides.
   - How Flame components (HUD, BladeTrail, BombComponent, glyph rendering in
     GlyphAtlas) should reference the same token values, so the in-game
     visuals and the Flutter UI shell feel like one coherent product.
   - Any notes on where the current code (alaif_game.dart, glyph_atlas.dart,
     hud.dart, the three overlay files) will need to change to adopt the new
     tokens — high-level only, don't write the implementation yet.

## Constraints

- **Portrait orientation only.**
- **Fully offline** — no network calls, no remote assets/fonts at runtime.
- **Performance-first** — this needs to hold 60fps on mid-range phones.
  Avoid heavy custom shaders, expensive blur/glow effects per-frame, or large
  uncompressed image assets. Prefer simple gradients, cached textures, and
  cheap particle effects. If you propose a glow/trail effect, explain its
  cost and a cheap fallback.
- **Respect Arabic cultural aesthetics.** Lean into geometric patterns,
  arabesque motifs, illuminated-manuscript-inspired ornamentation, and
  calligraphic forms as a genuine design language — not a superficial
  "exotic" reskin. Avoid kitsch, clichéd "magic carpet" tropes, or anything
  that feels like a stereotype rather than a style rooted in the actual
  tradition of Arabic calligraphy and ornament.
- The Arabic letters are the star — whatever direction you choose, the
  glyphs themselves (large, mid-flight, about to be sliced) must be the most
  visually striking element on screen.

## Process

Before producing the final spec, brainstorm 2-3 distinct visual directions
with me (e.g. short names + a paragraph each describing palette, type, mood,
and how each handles the background/HUD/overlays differently). Include
trade-offs (performance cost, implementation effort, how distinctive vs.
safe each direction is). Wait for me to pick a direction (or a hybrid) before
writing the full design spec and design tokens file.
```
