---
title: Alaif v1 Design
type: spec
created: 2026-06-09
updated: 2026-06-09
---

# Alaif v1 — Design Spec

Fruit Ninja–style 2D mobile game where players slice flying Arabic letters. Approved section-by-section on 2026-06-09. See [[game-vision]] for origin.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Arabic role | Purely aesthetic | Gameplay identical to Fruit Ninja; letters replace fruit visually |
| Backend | None — fully offline | Local scores/settings only; zero cost/complexity |
| Monetization | Paid upfront (one-time price) | Simplest code path; no IAP/ads plumbing |
| v1 scope | Classic mode only | One polished mode; expand post-v1 |
| Art direction | Letters ARE the objects | Big calligraphic glyphs get sliced in half; gradient-colored, dark background |
| Engine | Flutter + Flame | Game loop, components, gestures, particles built in; leverages Flutter background |

## Gameplay (Classic mode)

- All 28 Arabic letters in isolated form launch from the bottom of the screen in arcs.
- Swipe to slice. Slicing a letter splits it into two tumbling halves.
- Combos: 3+ letters in one swipe grants bonus points.
- Bombs: slicing one costs a life.
- 3 missed letters = game over. Local high score persists.
- Portrait orientation. Target 60fps.

## Architecture

Two worlds plus shared services:

**Flutter shell (widgets):** main menu, settings (sound/haptics), high scores, pause/game-over overlays (Flame overlay system).

**AlaifGame (FlameGame):**
- `Spawner` — emits waves of letters and bombs; difficulty curve ramps spawn rate/speed.
- `LetterComponent` — renders a cached glyph texture; moves on a gravity arc (plain math, no physics engine).
- `SlicedHalves` — two clipped halves of the glyph texture tumbling offscreen + particle burst.
- `BladeTrail` — pan gesture input; keeps ~100ms of points; renders glowing trail.
- `HUD` — score, combo indicator, lives.

**Shared services:**
- `GlyphAtlas` — at load, pre-renders all 28 letters to `ui.Image` textures via `TextPainter` (Flutter handles Arabic shaping natively; isolated forms avoid joining complexity).
- `Persistence` — high score + settings via `shared_preferences`.
- `Audio` — SFX/music via `flame_audio`.

**State machine:** menu → playing ⇄ paused → gameOver → (menu | replay).

## Data flow

Per frame: Spawner emits → letters follow arcs → pan gestures feed BladeTrail → segment-vs-circle hit tests against letters/bombs → on hit, swap LetterComponent for SlicedHalves (canvas `clipPath` on cached texture), update score/combo, fire haptic + sound → letters falling offscreen unhit decrement lives → game over writes high score.

## Error handling

- Corrupt/missing prefs → defaults.
- Audio load/play failure → non-fatal, silent.
- App backgrounded → auto-pause.
- Safe areas/notches respected; spawn tuning scales with screen size for fairness on tablets.

## Testing

- Pure-Dart unit tests: arc physics, segment-vs-circle hit tests, scoring/combos, difficulty curve.
- `flame_test`: component lifecycle (spawn, slice, despawn).
- Widget tests: menus and overlays.
- Manual: profile-mode runs on real devices for feel and 60fps.

## Roadmap

| Milestone | Deliverable |
|---|---|
| M0 | Flame hello-world + glyph-atlas spike (letter → texture → sliced halves) |
| M1 | Core loop: spawn, arc, slice, score |
| M2 | Rules: lives, bombs, combos, game over, high score |
| M3 | Juice: particles, trail glow, audio, haptics |
| M4 | Menus, settings, polish |
| M5 | Store prep: icons, screenshots, paid listing (iOS + Android) |

## Risks

- **Glyph slicing visuals** (biggest unknown) — de-risked first in M0 spike.
- **Game feel/tuning** — iterative; budget time in M2/M3.
- **Paid-upfront discoverability** — business risk, not technical; revisit post-launch.

Related: [[game-vision]], [[index]]
