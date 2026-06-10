# Alaif — Visual Design Spec (v1 · "Ink & Paper")

*Created 2026-06-09 from the visual design session. Pairs with `design_tokens.dart`
and `alaif_theme.dart`. Visual reference: `Alaif — Ink and Paper.html`.*

Related: [[alaif-v1-design]], [[game-vision]]

---

## 1. Art direction & mood

**Black calligraphy on warm paper.** Alaif looks like a page from a calligrapher's
practice book that has come alive: large Aref-Ruqaa glyphs fly up, you cut them
with a brush-ink stroke, and they burst into ink splatter (with gold dust on a
combo). The brand mark is a single vermillion **seal** — like a calligrapher's
signature stamp. Calm, confident, gallery-like; the opposite of neon arcade.

This is a deliberate inversion of the current build:

| | Current (M0–M2) | Ink & Paper (target) |
|---|---|---|
| Background | dark purple-black `0xFF120C1D` | warm paper `0xFFEDE7D8` |
| Glyph fill | gold→orange gradient | near-black **ink** gradient `glyphTop→glyphBottom` |
| Blade trail | (glow, light) | dark **brush ink** stroke |
| Cut feedback | — | ink splatter |
| Combo | — | gold-dust sparkle |
| Accent | — | vermillion seal `#B23A2B` |

> The flip from dark→light is the single biggest migration. Everything that was
> "bright thing on dark" becomes "dark thing on light." The glyphs stay the hero;
> they just go from glowing gold to bold ink.

---

## 2. Color palette

All defined in `AlaifColors`.

| Token | Hex | Role |
|---|---|---|
| `paper` | `#EDE7D8` | background / game canvas |
| `paperDeep` | `#E4DCC8` | gradient floor, vignette |
| `scrim` | `#EDE7D8` @ 0.78 | paper wash over the paused game |
| `ink` | `#1B1712` | glyphs, headings, primary buttons, blade |
| `inkSoft` | `#2A251E` | body text |
| `inkMuted` | `#867C6C` | labels, captions, secondary |
| `hairline` | `#1B1712` @ 0.14 | dividers, ghost-button borders |
| `seal` | `#B23A2B` | brand mark, combo, danger / life-lost |
| `sealDark` | `#8E2C20` | pressed states |
| `gold` | `#A8842F` | score-up highlight |
| `goldDust` | `#C9A24B` | combo particle glint |
| `glyphTop / glyphBottom` | `#2C2720 / #14110B` | vertical glyph gradient |

**Semantic:** score-up → `gold`; life-lost & bomb danger → `seal`; combo → `seal`
text with `goldDust` particles; game-over → `ink`.

---

## 3. Typography

Two families, both **SIL Open Font License 1.1** (free to bundle & ship; include
each font's `OFL.txt` in the app). **Vendor the TTFs** under
`app/assets/fonts/` — do *not* use the `google_fonts` package, which fetches at
runtime and this game is fully offline.

| Family | Source | Use |
|---|---|---|
| **Aref Ruqaa** | Google Fonts (OFL) | the sliced hero glyphs + Arabic accents (`الألِف`) |
| **Spectral** | Google Fonts (OFL) | all Latin UI: titles, scores, body, buttons |

Roles are defined as `const TextStyle` in `AlaifType` and wired into `ThemeData`
(§7). Flame's `TextPaint(style: AlaifType.scoreHud)` consumes the same consts, so
HUD and overlays never drift.

| Role | Style |
|---|---|
| `titleDisplay` | Spectral *italic* 64 |
| `heading` | Spectral *italic* 32 / 500 |
| `scoreHud` | Spectral 40 / 500, tabular |
| `scoreLarge` | Spectral 76 / 400, tabular |
| `label` | Spectral 12 / 500, +2.6 tracking, UPPERCASE |
| `combo` | Spectral *italic* 20, seal |
| `button` | Spectral *italic* 19, on-ink |
| `body` / `bodyMuted` / `caption` | Spectral 16 / 15 / 13 |

**pubspec.yaml:**
```yaml
flutter:
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
        - asset: assets/fonts/Spectral-Italic.ttf
          style: italic
        - asset: assets/fonts/Spectral-Medium.ttf
          weight: 500
        - asset: assets/fonts/Spectral-MediumItalic.ttf
          weight: 500
          style: italic
    - family: ArefRuqaa
      fonts:
        - asset: assets/fonts/ArefRuqaa-Regular.ttf
        - asset: assets/fonts/ArefRuqaa-Bold.ttf
          weight: 700
```

---

## 4. Per-screen specs

Phones are portrait, `screenPad` = 38 left/right. Primary button is ink-filled,
full-width, radius 4. Secondary is ghost (hairline border). Tertiary is an
underlined text link.

### 4.1 Main menu
```
┌──────────────────────────┐
│ [■seal alif]  A SLICING…  │  seal stamp + tracked label + الألِف (seal)
│                           │
│   Alaif                   │  titleDisplay, italic, ink
│   ──                      │  64×2 seal rule
│   Swipe to slice the      │  bodyMuted, max ~230w
│   falling letters.        │
│                           │
│   BEST            14,820  │  label (muted) · scoreHud-ish ink
│  ┌──────────────────────┐ │
│  │        Play          │ │  primary (ink)
│  └──────────────────────┘ │
│     How to play   Sound   │  text links (muted, hairline underline)
└──────────────────────────┘
```
Faint giant `ل` watermark bottom-right at 5% ink. Background = paper gradient +
lattice (§6).

### 4.2 How to play
Seal + `heading` "How to play". Three rows, each a 56px hairline-bordered icon
tile + italic `subheading` + `bodyMuted`:
1. **Swipe to slice** — curved ink stroke w/ arrowhead.
2. **Chain combos** — three ink dots + gold dust.
3. **Avoid the bombs** — ink bomb glyph, seal spark.
Primary "Got it" pinned to bottom.

### 4.3 In-game HUD (the layer M3 dresses)
```
 SCORE                       ● ● ○   ← lives: filled ink / hollow hairline
 8,640                               score: scoreHud ink, top-left, safe-area
            four in a row            combo callout: combo style (seal italic),
                                     centered ~y150, fades after comboFlashMs
```
- **Score** top-left under safe area (`label` + `scoreHud`).
- **Lives** top-right: 3 dots, 14px, filled `ink` = alive, hairline ring = lost.
- **Combo** centered callout; spell small counts ("two… three… four in a row")
  or show `×N` for big chains. Seal, italic, scales+fades in `comboFlashMs`.
- **Bomb**: dark radial ink sphere, **seal** 2px ring, short fuse with a
  `goldDust` spark, white-`!` cut to ink. Reads as "danger" by the red ring.
- **Sliced glyph**: two ink halves tumble apart along the cut; ink splatter at
  the seam; brush-ink blade streak crosses it.

### 4.4 Pause
Paper `scrim` (0.78) over the frozen game (faint glyph still visible behind).
Centered: `PAUSED` label, big `scoreLarge` current score (italic ink),
`CURRENT SCORE` label. Primary **Resume**; row of two ghosts **Restart /
Settings**; text link **Quit to menu**.

### 4.5 Game over
Faded sliced glyph up top. Bottom-anchored: seal italic line *"The blade rests"*,
`FINAL SCORE` label, `scoreLarge` final, then two stat columns split by a
hairline (**Best**, **Best combo**). Primary **Play again**; ghost **Main menu**.

### 4.6 Settings
`heading` "Settings" + seal rule. Hairline-divided rows with ink-pill switches:
**Sound effects**, **Music**, **Haptics** (each with a muted sub-label). A
hairline card shows **Best score**. Footer: `Alaif · v1.0 · made offline`.
Primary **Done**.

---

## 5. App icon (pick one for M5)

All adaptive-safe (keep the alif within the center ~66% safe zone; provide a
solid background layer).

1. **alif + cut** — ink `ا` on paper with the lattice and a single ink slash.
   Quietest, most "calligraphy".
2. **ink ground** — paper `ا` on **ink** field + tiny seal corner. Highest
   contrast at small sizes; best legibility on a busy home screen.
3. **seal** — paper `ا` centered on a **seal-red** field with a thin inset
   border. Boldest, most brand-forward; reads as a stamp.

Recommendation: **#3 (seal)** for the store icon (pops in the grid), **#1** as
an in-app/splash mark.

---

## 6. Background (must stay cheap → 60fps)

Paper gradient + a faint geometric **girih lattice** (two overlapped squares =
8-point star, tiled).

- **Cheapest (recommended):** pre-render one lattice tile to a `ui.Image` **once**
  at load, then paint the background each frame as `paper` gradient + one
  `drawRect` with an `ImageShader(tile, TileMode.repeated, …)`. ~2 draw calls,
  zero per-frame procedural work.
- **Fallback:** solid `AlaifColors.paper`, no lattice. Looks fine; ship this if
  the atlas/profile budget is tight.
- **Avoid:** per-frame path tessellation or any full-screen blur.

---

## 7. Implementation guidance

### 7.1 Material overlays → ThemeData
`buildAlaifTheme()` (in `alaif_theme.dart`) maps the tokens so menu / pause /
game-over / how-to / settings widgets style themselves:
- `ElevatedButton` → ink-filled, radius 4, `AlaifType.button`.
- `OutlinedButton` → ghost w/ hairline border.
- `TextButton` → muted text link.
- `Switch` → ink pill (`switchTheme`).
- `Divider` → hairline.
- `TextTheme` carries the type roles (use `Theme.of(context).textTheme` or the
  `AlaifType` consts directly).

Wrap once: `MaterialApp(theme: buildAlaifTheme(), …)`.

### 7.2 Flame layer → same tokens
Flame `TextPaint` takes a `TextStyle`, so HUD/callouts use the identical consts:
```dart
final scorePaint = TextPaint(style: AlaifType.scoreHud);
final comboPaint = TextPaint(style: AlaifType.combo);
```
Glyphs, blade, bombs, particles all read `AlaifColors` / `AlaifGradients` /
`AlaifMotion`. One palette, two renderers.

### 7.3 Where the current code changes (high-level)

| File | Change |
|---|---|
| `app/lib/game/alaif_game.dart` | Background `0xFF120C1D` → `AlaifColors.paper`. Add a low-priority `PaperBackground` component (gradient + cached lattice shader, §6). Keep overlay wiring; point overlays at the themed widgets. |
| `app/lib/core/glyph_atlas.dart` | Replace gold→orange gradient (`0xFFFFD97A`→`0xFFFF9D3D`) with `AlaifGradients.glyph` via `Paint()..shader = …createShader(rect)` on the `TextPainter`. Render with `ArefRuqaa` at `AlaifGlyph.renderFontSize`; bake `AlaifGlyph.shadow*` for soft depth on paper. Texture padding = `AlaifGlyph.texturePadding`. |
| `app/lib/game/hud.dart` | Replace the single plain `TextComponent` with: score (`AlaifType.scoreHud`, top-left, safe-area + `AlaifSpacing`), lives as 3 dots (filled `ink` / hairline ring), and a center combo callout (`AlaifType.combo`, fades over `comboFlashMs`). |
| `BladeTrail` | Recolor to `AlaifColors.bladeInk`; width `AlaifMotion.bladeWidth`→`bladeMinWidth` taper; retain `bladeRetentionMs`. Optional 1px blur glow (see perf). |
| `BombComponent` | Dark ink radial sphere, `seal` 2px ring, `goldDust` fuse spark, ink `!`. |
| Particles (`SlicedHalves` + new) | Cut = `cutInkParticles` ink dots (`cutParticle*` speeds/life); halves tumble `cutHalfTumbleMs`; combo = `comboDustParticles` `goldDust` glints. |
| `menu_overlay.dart`, `game_over_overlay.dart`, `pause_overlay.dart` | Rebuild per §4 using themed `ElevatedButton`/`OutlinedButton`/`TextButton`; drop default `TextStyle`s. |
| **new:** `how_to_overlay.dart`, `settings_overlay.dart` | M4 surfaces (§4.2, §4.6). Register in the overlay map; settings reads/writes `Persistence`. |

### 7.4 Performance notes
- **Blade glow** on a light ground is optional — solid ink reads well without it.
  If you want it: one extra wider, ~0.25-opacity stroke pass with
  `MaskFilter.blur(BlurStyle.normal, 2)`. Cost: one extra stroked path/frame
  (cheap for a thin line). **Fallback:** drop the blur pass.
- **Glyph textures** are pre-rendered once in `GlyphAtlas` (28 letters) and
  reused — no per-frame text layout. Keep `renderFontSize` generous and scale
  down per spawn so big glyphs stay crisp.
- **Sliced halves** reuse the cached texture with a `clipPath` — no re-render.

---

## 8. Asset list

| Asset | Source / note |
|---|---|
| `Spectral-Regular/Italic/Medium/MediumItalic.ttf` | Google Fonts, OFL 1.1 — vendor under `assets/fonts/`, ship `OFL.txt` |
| `ArefRuqaa-Regular/Bold.ttf` | Google Fonts, OFL 1.1 — vendor, ship `OFL.txt` |
| Lattice tile | generated at runtime to a `ui.Image` (no asset needed) — or bake a small PNG if preferred |
| Cut/combo particles | solid-color circles drawn in canvas — **no texture asset required** |
| App icon source | one of §5; produce 1024² master → iOS asset catalog + Android adaptive (foreground alif + solid bg layer) |
| SFX (M3) | slice / bomb / combo / miss — `flame_audio`; load failure is non-fatal per the design spec |

---

## 9. Milestone fit

- **M3 (juice):** §4.3 + §7.2–7.4 — blade ink trail, ink-splatter cuts, gold-dust
  combos, bomb styling, HUD dressing, haptics on slice/miss. Tuning lives in
  `AlaifMotion`.
- **M4 (menus/polish):** §4.1, 4.2, 4.4, 4.5, 4.6 via `buildAlaifTheme()`; add the
  two new overlays.
- **M5 (store prep):** §5 icon, plus screenshots staged on these screens.
