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
3. **Ink-aware cutting**: at atlas build, pixel-scan each glyph image for its tight ink rect (one-time, 28 letters). Hit circle sized/centered from ink bounds. Cut line passes through ink center along the actual swipe direction; halves are rendered with half-plane `Path` clips and separate perpendicular to the cut.

## Error handling

Pixel scan failure → fall back to full texture bbox (current behavior). Empty ink rect → bbox. Insets unavailable → zero padding.

## Testing

TDD per task; existing 110 tests stay green. New tests: ink-rect scan math, sliced-flag dedup, SFX cooldown, swipe-angle cut geometry, inset-aware HUD positions.

Related: [[alaif-m3-m4-design]], [[index]]
