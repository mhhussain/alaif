---
title: Difficulty & Spawning Design (v2)
type: spec
created: 2026-06-16
updated: 2026-06-16
---

# Difficulty & Spawning Design (v2)

Supersedes the time-based ramp described in [[alaif-v1-design]] (Spawner section).
This page is the grounding source of truth for how the game escalates.

## Goals

v1 shipped a minimal loop (one spawn at a time, linear time ramp). v2 makes
the moment-to-moment game *feel* better and gives skilled players room to push:

- Letters appear faster and in greater volume as the run progresses.
- Multiple letters on screen at once (not just one).
- Punctuated **surge events**: a rush of letters, a rush of bombs, or a dense mix.
- Score (not raw time) drives the pace — combos let strong players accelerate.

## Difficulty model

**Discrete stages, advanced by score.** Score is the single source of truth: a
player who racks up combos reaches harder stages sooner than a cautious one.
Three stages for v2 (more is a later tuning exercise):

| Stage  | Score range | Baseline interval | Baseline batch | Letter speed | Bomb % |
|--------|-------------|-------------------|----------------|--------------|--------|
| Calm   | 0–299       | 1.10s             | 1              | ×1.00        | 5%     |
| Brisk  | 300–899     | 0.80s             | 1–2            | ×1.15        | 12%    |
| Frenzy | 900+        | 0.55s (floor)     | 2–3            | ×1.30        | 20%    |

- **Baseline interval** — seconds between baseline spawn ticks for the stage.
- **Baseline batch** — letters emitted per tick (range = uniform random).
- **Letter speed** — multiplier on the spawn arc's vertical launch speed.
- **Bomb %** — chance a given baseline spawn is a bomb instead of a letter.

Numbers are starting points; expect tuning after playtesting.

## Surges

Within a stage, a **surge** is a short, dense burst layered on top of baseline
spawning. Surges fire on a **timed cadence** (predictable rhythm, easy to tune
and test). Their flavor escalates with stage.

| Stage  | Cadence | Count | Letter / Bomb / Both |
|--------|---------|-------|----------------------|
| Calm   | ~12s    | 3     | 80 / 10 / 10         |
| Brisk  | ~10s    | 5     | 55 / 25 / 20         |
| Frenzy | ~8s     | 8     | 35 / 35 / 30         |

- **Cadence** — interval between surge rolls while in the stage.
- **Count** — items in the surge (stage-scaled).
- **Type probability** — escalates from mostly letter-surges early to more
  bomb/both surges late (natural escalation).

Surge types:

- **Letter-surge** — a rapid fan of letters; combo bait, high reward.
- **Bomb-surge** — mostly bombs, few/no letters; a restraint test (don't slice).
- **Both-surge** — dense mixed rush; high risk / high reward.

Surge mechanics: sub-spawns emitted rapidly (~0.15s apart) with a faster arc
than baseline, so a surge reads as a distinct rush rather than a faster trickle.

## Combo scoring

Base remains 10 points per letter. A multi-letter swipe multiplies the whole
swipe by the number of cuts, capped at ×4:

```
swipePoints = 10 × cuts × min(cuts, 4)
```

| Cuts | Points |
|------|--------|
| 1    | 10     |
| 2    | 40     |
| 3    | 90     |
| 4    | 160    |
| 5    | 200    |
| 6    | 240    |

The ×4 cap stops late-game surges from exploding the score while still rewarding
big chains. (This replaces v1's flat +5/letter bonus above a 3-hit threshold.)

## The cap (a design floor, not a perf hack)

Difficulty is bounded:

- **Interval floor:** baseline interval never drops below 0.55s.
- **Max concurrent items (~12):** if the on-screen item count is at the cap, a
  baseline spawn is skipped; surges are gated against the same limit.

Rationale — steady-state concurrency is already self-bounded (≈ transit time ÷
spawn interval, ~8–10 items). The real risk is a surge stacking on a near-floor
pace, briefly doubling that. Flame can render hundreds of components; the cap is
about **fairness and readability** — an unwinnable wall of items feels broken —
not about preventing a crash.

## Architecture (implementation sketch)

- `core/difficulty_curve.dart` → reworked into a stage model. `stageFor(score)`
  returns a `Stage` carrying all per-stage params (interval, batch, speed,
  bomb %, surge cadence/count/type weights). Drops the time-based ramp.
- `game/spawner.dart` — baseline batch spawn driven by the current stage (read
  from `scoreState.score`); enforces the concurrency gate.
- New `game/surge_scheduler.dart` (component) — cadence timer, rolls surge type
  by stage weights, emits the rapid sub-spawns.
- `core/score_state.dart` — the combo multiplier formula above.

## Open / deferred

- More than 3 stages, or smooth interpolation between stage params.
- Per-letter difficulty (some glyphs harder to read at speed).
- Surge telegraphing (aud/visual warning before a bomb-surge).

See [[alaif-v1-design]] for the broader game spec and roadmap.
