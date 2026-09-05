# CLAUDE.md — app/

The *Alaif* Flutter app (Android + iOS): Fruit Ninja–style slicing of Arabic
letters, built with Flutter + Flame. Fully offline — no backend; local
persistence via `shared_preferences`.

## Layout

- `lib/core/` — pure game logic (score, rules, difficulty stages, word state,
  glyph atlas, hit testing). No Flame dependencies where avoidable.
- `lib/game/` — Flame components (`AlaifGame`, spawners, letters, bombs, HUD,
  blade, particles).
- `lib/ui/` — Flutter overlays (menu, pause, game over, settings) and design
  tokens (`design_tokens.dart`, "Ink & Paper" theme).
- `lib/services/` — audio, haptics, settings, high scores.
- `test/` mirrors `lib/`.

## Modes

`GameMode.classic` (endless slicing, bombs, surges) and `GameMode.wordBuilder`
(slice the current word's letters in order — see `../wiki/word-builder-mode.md`).

## Rules

- Read `../CLAUDE.md` and `../wiki/index.md` for project context before working here.
- Architecture/design decisions live in the wiki, not in code comments.
- Before claiming done: `flutter analyze` clean + `flutter test` green.
