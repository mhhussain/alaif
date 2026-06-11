# Log

## [2026-06-11] decision | Audio/haptics/bomb FX/topbar fixes plan written
4-task TDD plan at plans/2026-06-11-polish-2-fixes: AudioService bgm controls wired into AlaifGame lifecycle, AndroidManifest VIBRATE permission, spawnBombBurst ink-splat reusing InkBurstComponent, ControlsOverlay padding fix to clear HUD lives dots. Branch fix/polish-2. Ready for subagent-driven execution.

## [2026-06-11] decision | Audio/haptics/bomb FX/topbar fixes spec approved
Spec [[audio-haptics-bomb-topbar-fixes]] approved: bg music loop via FlameAudio.bgm started on load and paused with game pause/lifecycle, Android VIBRATE permission for already-wired haptics, ink-splat bomb effect reusing slice burst component, pause button repositioned to clear HUD lives dots. Branch fix/polish-2. Implementation plan next.

## [2026-06-11] decision | Device review fixes executed (rev 2)
All 11 tasks executed via subagents on fix/device-review-1 (local only, awaiting device verification): slice dedup + SFX cooldown, true edge-to-edge with live safe-area insets into HUD, Katibeh font, deckled paper carrier cards under glyphs, swipe-angle rotation-aware cuts with speed-scaled impulse, hit-stop. 143 tests passing, analyze clean. Review fixes: live MediaQuery inset sync (stateful game host), restored approved card color (test heuristic was the bug), rotation-aware cut frames + cached clip path + spawner toss wiring.

## [2026-06-10] decision | Device review fixes revised: carrier-card slicing + Katibeh
Second device pass: bare-glyph cuts can't feel good (thin/concave/dotted glyphs ⇒ empty halves; vector outlines and shader masks rejected — they don't change what lands in each half). New approach: glyph baked onto deckled paper card, slice the composite, swipe-angle half-plane cut, swipe-scaled impulse, hit-stop. Font → Katibeh (closest OFL Thuluth-flavored; no genuine open Thuluth exists). Spec [[device-review-1-fixes]] updated; plan rev 2 (11 tasks) supersedes ink-rect tasks 5-9.

## [2026-06-10] decision | Device review 1 fixes planned
Device testing (raw/review_1.md) surfaced: not edge-to-edge (SafeArea + white scaffold), overlapping slice SFX (per-drag-update re-slicing before deferred removal), trivial-sliver cuts (fixed horizontal 50% bbox split, swipe angle ignored). Spec [[device-review-1-fixes]]; 10-task plan at plans/2026-06-10-device-review-1-fixes on branch fix/device-review-1. Awaiting user review.

## [2026-06-10] decision | Ink & Paper M3+M4 plan executed
All 22 tasks of plans/2026-06-09-ink-and-paper-m3-m4 executed via subagent-driven development on feature/ink-and-paper-m3-m4. 110 tests passing, flutter analyze clean. Each task passed spec + quality review; review fixes: paint/shader hoisting (paper bg, blade, bomb, particles), ui.Image disposal, SafeArea + scroll wrappers on full-screen overlays, ink pause icon. M5 (store prep) next after device testing.

## [2026-06-10] decision | Ink & Paper M3+M4 plan written
23-task TDD plan at plans/2026-06-09-ink-and-paper-m3-m4: foundation (tokens/theme/fonts), game-layer migration, juice (particles, combo, HUD, haptics, audio w/ slice SFX from raw/splat.mp3), menus (rebuilt + how-to + settings), final verification. Branch feature/ink-and-paper-m3-m4. Awaiting user review.

## [2026-06-09] decision | M3+M4 design approved (Ink & Paper)
Scoped one plan for M3+M4; M5 separate. Full Ink & Paper adoption (paper bg, ink glyphs, lattice). Audio wired with stubbed SFX. Spec: [[alaif-m3-m4-design]]; visual source of truth in raw/design/deliverables/.

## [2026-06-09] ingest | Repo bootstrap + SESSION_HANDOFF.md
Instantiated the LLM Wiki pattern: created CLAUDE.md schema, wiki/ (index, log), raw/, and app/ placeholder. Ingested SESSION_HANDOFF.md into [[game-vision]]. Brainstorming phase begun.

## [2026-06-09] decision | M0–M2 core game implemented + pause button
Core game complete per plans/2026-06-09-alaif-core-game-m0-m2 on branch feature/core-game-m0-m2: playable Classic mode (slicing, combos, bombs, lives, game over, persisted high score), 54 tests passing. User verified on iOS simulator. Pause button added per plans/2026-06-09-pause-button. Added [[design-brief-prompt]] and [[testflight-deployment]]. Next: device testing via TestFlight, then visual design pass (M3).

## [2026-06-09] decision | Alaif v1 design approved
Brainstorm concluded: aesthetic-only letters, fully offline, paid upfront, Classic mode only, "letters ARE the objects" art direction, Flutter + Flame. Spec written to [[alaif-v1-design]].
