---
title: Alaif M3+M4 Design (Ink & Paper)
type: spec
created: 2026-06-09
updated: 2026-06-09
---

# Alaif M3+M4 — Design Spec

Single plan covering M3 (juice) + M4 (menus/polish), adopting the **Ink & Paper** visual design **fully** (paper background, ink glyphs, lattice included). Authoritative visual spec: `raw/design/deliverables/visual-design-spec.md`; tokens: `design_tokens.dart`, theme: `alaif_theme.dart` (same dir). Builds on [[alaif-v1-design]]; M0–M2 complete and user-verified.

## Decisions

| Decision | Choice |
|---|---|
| Plan scope | M3+M4 in one plan; M5 (store prep) planned separately after device testing |
| Visual design | Adopt Ink & Paper fully as specified, including girih lattice background |
| Audio | Wire `AudioService` + hooks now; SFX assets stubbed — missing files are silent/non-fatal. User drops in real CC0 sounds later |
| Fonts | Vendor Spectral + ArefRuqaa TTFs (OFL 1.1) under `app/assets/fonts/`, ship OFL.txt; no google_fonts (offline) |

## File map

**New:**
- `app/lib/ui/design_tokens.dart`, `app/lib/ui/alaif_theme.dart` — copied from `raw/design/deliverables/`
- `app/lib/game/paper_background.dart` — paper gradient + cached lattice `ImageShader` tile (spec §6)
- `app/lib/game/combo_callout.dart` — centered seal-italic combo text, fades over `comboFlashMs`
- `app/lib/core/ink_particles.dart` — ink-splatter cut burst + gold-dust combo burst (canvas circles, no assets)
- `app/lib/services/audio_service.dart` — flame_audio wrapper; load/play failures non-fatal
- `app/lib/services/haptics_service.dart` — slice/bomb/miss haptics, toggleable
- `app/lib/services/settings.dart` — sound/music/haptics flags via shared_preferences
- `app/lib/ui/how_to_overlay.dart`, `app/lib/ui/settings_overlay.dart` — spec §4.2, §4.6

**Modified:**
- `glyph_atlas.dart` — ArefRuqaa @ `renderFontSize`, `AlaifGradients.glyph`, baked shadow, `texturePadding`
- `alaif_game.dart` — background → paper; add PaperBackground; register new overlays
- `hud.dart` — score (scoreHud, top-left), lives as 3 ink dots (top-right), combo callout
- `blade_trail.dart` — `bladeInk` color, width taper 7→1.5, retention 110ms
- `bomb_component.dart` — ink sphere, seal ring, goldDust fuse spark
- `sliced_halves.dart` — tumble timing `cutHalfTumbleMs`; trigger ink splatter
- `menu_overlay.dart`, `pause_overlay.dart`, `game_over_overlay.dart` — rebuilt per spec §4
- `main.dart` — `MaterialApp(theme: buildAlaifTheme())`
- `pubspec.yaml` — fonts block, `flame_audio`, haptics dep

## Error handling

Missing/failed SFX → silent, non-fatal. Settings prefs corrupt/missing → defaults (all on). Lattice render failure → solid paper fallback.

## Testing

Unit tests per new service/particle math; widget tests per overlay; flame_test for PaperBackground/ComboCallout lifecycle. Existing 54 tests stay green (some assert color values — update those to token values).

Related: [[alaif-v1-design]], [[index]]
