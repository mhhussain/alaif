---
title: Device Review 1 Fixes
type: spec
created: 2026-06-10
updated: 2026-06-10
---

# Device Review 1 — Fixes Spec

Fixes for three issues found testing on a real device (`raw/review_1.md`). Builds on [[alaif-m3-m4-design]]; branch `fix/device-review-1` off `feature/ink-and-paper-m3-m4`.

## Issues & root causes

| # | Issue | Root cause |
|---|---|---|
| 1 | Game not full-height (notch excluded, white bottom strip) | `main.dart` wraps `GameWidget` in `Scaffold` + `SafeArea`; default white scaffold bg; no edge-to-edge `SystemChrome` mode |
| 2 | Slice SFX overlaps itself | `trySlice` runs per drag-update; letter removal is deferred to next tick so one swipe slices the same letter repeatedly, each firing `FlameAudio.play` (new player per call) |
| 3 | Cuts sever trivial slivers | Cut is always horizontal at 50% of texture bbox; Arabic glyph ink is not centered in its font-metric box; swipe angle ignored; hit circle from bbox not ink |

## Decisions

1. **Edge-to-edge**: `SystemUiMode.edgeToEdge`, remove `SafeArea` around `GameWidget`, `Scaffold(backgroundColor: AlaifColors.paper)`. Safe-area insets passed into the game for HUD placement; `controls` overlay (pause) gets `SafeArea`. Full-screen menu overlays already have SafeArea wrappers.
2. **Slice dedup**: synchronous `sliced` flag on `LetterComponent`, checked in `trySlice` (also prevents double score/combo). Plus a ~60ms slice-SFX cooldown in `AudioService` as a backstop.
3. **Carrier-card slicing** *(supersedes the earlier ink-rect pixel-scan approach after device testing showed bare-glyph cuts can't feel good)*: each glyph is baked onto a slightly-rotated warm paper card with deckled edge + baked shadow, as one composite texture. Hit circle and cut geometry derive from the card's known geometry (no pixel scan). Cut passes through card center along the actual swipe direction via half-plane `Path` clips; halves separate with a swipe-scaled impulse. Juice: brief hit-stop on slice, SFX synced to the cut frame. Rationale: straight clips on thin/concave/dotted Arabic glyphs inevitably produce empty halves; vector outlines (no Flutter text-to-path, no stable path booleans) and shader masks don't change what lands in each half; a solid near-convex carrier does.
4. **Font**: Katibeh (OFL 1.1, Google Fonts) replaces ArefRuqaa for hero glyphs — closest open Thuluth-flavored face (no genuine Thuluth digitization is openly licensed). User's larger spawn sizes (196–332) kept.

## Error handling

Insets unavailable → zero padding. Degenerate swipe vector → horizontal cut fallback. Font load failure → system Arabic fallback renders (no crash).

## Testing

TDD per task; existing 110 tests stay green. New tests: sliced-flag dedup, SFX cooldown, carrier geometry (hit circle/cut center), swipe-angle cut geometry + impulse, hit-stop timing, inset-aware HUD positions, Katibeh asset registration.

Related: [[alaif-m3-m4-design]], [[index]]
