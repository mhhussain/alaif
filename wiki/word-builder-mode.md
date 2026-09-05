---
title: Word Builder mode — design decisions
type: decision
created: 2026-07-14
updated: 2026-07-14
---

# Word Builder mode — design decisions

Second game mode (branch `feature/word-builder-mode`): slice the letters of a
target Arabic word **in order** to complete it. Implementation plan lives at
`docs/superpowers/plans/2026-06-28-word-builder-mode.md`; this page records the
decisions and where the shipped build deviates from that plan.

## Context

Classic mode is aesthetic-only slicing. Word Builder adds a light educational
hook — building real words letter-by-letter — without a backend, keeping the
offline-first constraint from [[alaif-v1-design]].

## Decisions

- **Order enforcement**: only the *next* letter of the word counts; slicing it
  advances `WordState.targetIndex`. Slicing a wrong word-letter is a miss.
- **Scoring tiers**: 100 / 150 / 200 points for completing 3- / 4- / 5-letter
  words (`WordState.pointsForCurrentWord`).
- **Score-ramped word buckets**: word length ramps with score — 3-letter words
  below 300, 4-letter below 900, 5-letter after (`AlaifGame._startNextWord`).
- **No bombs, no surges** in Word Builder; only the current word's letters
  spawn (`WordBuilderSpawner`), in clusters on a 2s interval.
- **Cluster sizes [1, 3]** — the plan proposed [1, 3, 5], but 5-glyph clusters
  crowded small screens after on-device tuning, so capped at 3.
- **Miss penalty**: only letting the *target* letter fall off-screen costs a
  life; non-target letters fall free.
- **Word-complete beat**: 0.5s spawn pause + remaining letters cleared + combo
  SFX on completion, then the next word starts.
- **Mode-keyed high scores**: `HighScoreStore` persists one high score per
  `GameMode`; menu buttons are "Classic Mode" and "Word Builder".
- **HUD word display**: current word top-center under the lives row, RTL
  visual order, 40px glyphs / 52px spacing (raised from 24/32 for
  readability), target letter in ink, done letters hairline, upcoming at 40%.

## Consequences

- `GameMode` enum threads through startGame, restart overlays ("Play again"
  restarts the *active* mode), and high-score persistence.
- Launch physics shared between `Spawner` and `WordBuilderSpawner` via
  `lib/game/launch_arc.dart` — tune arcs in one place.
- Word lists (`lib/core/word_list.dart`) are curated constants; growing them
  or adding tiers means touching the bucket thresholds too (candidate for a
  future `WordTier` type).
