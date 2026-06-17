# Difficulty v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the time-based linear spawn ramp with a score-driven stage model, multi-letter baseline batches, timed surge events, and a combo-multiplier score, per [[difficulty-design]].

**Architecture:** A pure `Stage` model + `stageFor(score)` lookup replaces `DifficultyCurve`. `Spawner` reads the current stage each tick (from `game.scoreState.score`), emits a stage-scaled batch through a shared `spawnItem` method, and enforces a concurrency cap. A new `SurgeScheduler` component layers timed, type-rolled bursts on top using the same `spawnItem`. `ScoreState` switches to a `10 × cuts × min(cuts, 4)` per-swipe formula.

**Tech Stack:** Dart / Flutter, Flame game engine, `flame_test` (`testWithGame`), `flutter_test`. Working directory for ALL commands: `/Users/iammoo/code/alaif/app`.

## Global Constraints

- All `flutter` / `dart` commands run from `/Users/iammoo/code/alaif/app`.
- Numbers below are the approved spec values — copy them verbatim.
- Stage thresholds: Calm `score 0–299`, Brisk `300–899`, Frenzy `900+`.
- Baseline: Calm `interval 1.10s, batch 1, speed ×1.00, bomb 5%`; Brisk `0.80s, 1–2, ×1.15, 12%`; Frenzy `0.55s, 2–3, ×1.30, 20%`.
- Surges: Calm `cadence 12s, count 3, weights .80/.10/.10`; Brisk `10s, 5, .55/.25/.20`; Frenzy `8s, 8, .35/.35/.30` (letter/bomb/both).
- Combo score: `swipePoints = 10 × cuts × min(cuts, 4)`. Replaces v1 flat +5/letter.
- Cap: baseline interval floor `0.55s` (already the Frenzy value — no extra clamp needed); max concurrent items `12` (letters + bombs); surge sub-spawn interval `~0.15s`; surge arc speed boost `×1.25`.
- After EVERY task: `flutter analyze` must be clean and the full `flutter test` suite green before commit.
- Do not loop on a failing tool more than 3 times; stop and report.

---

### Task 1: Stage model + `stageFor(score)`

Replace the time-based `DifficultyCurve` with a pure, score-indexed stage table. This file has no Flame/Flutter dependency — keep it a plain Dart model so it stays trivially unit-testable.

**Files:**
- Modify (full rewrite): `lib/core/difficulty_curve.dart`
- Modify (full rewrite): `test/core/difficulty_curve_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class Stage` with `const` constructor and final fields: `String name`, `double baselineInterval`, `int batchMin`, `int batchMax`, `double letterSpeed`, `double bombChance`, `double surgeCadence`, `int surgeCount`, `double surgeLetterWeight`, `double surgeBombWeight`, `double surgeBothWeight`.
  - Top-level `Stage stageFor(int score)` returning the Calm/Brisk/Frenzy stage.
  - Top-level `const` instances `kCalm`, `kBrisk`, `kFrenzy`.

- [ ] **Step 1: Write the failing test**

Replace the entire contents of `test/core/difficulty_curve_test.dart` with:

```dart
import 'package:alaif/core/difficulty_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stageFor returns Calm below 300', () {
    expect(stageFor(0).name, 'Calm');
    expect(stageFor(299).name, 'Calm');
  });

  test('stageFor returns Brisk in 300..899', () {
    expect(stageFor(300).name, 'Brisk');
    expect(stageFor(899).name, 'Brisk');
  });

  test('stageFor returns Frenzy at 900+', () {
    expect(stageFor(900).name, 'Frenzy');
    expect(stageFor(99999).name, 'Frenzy');
  });

  test('Calm baseline params match spec', () {
    final s = kCalm;
    expect(s.baselineInterval, 1.10);
    expect(s.batchMin, 1);
    expect(s.batchMax, 1);
    expect(s.letterSpeed, 1.00);
    expect(s.bombChance, 0.05);
  });

  test('Frenzy baseline params match spec', () {
    final s = kFrenzy;
    expect(s.baselineInterval, 0.55);
    expect(s.batchMin, 2);
    expect(s.batchMax, 3);
    expect(s.letterSpeed, 1.30);
    expect(s.bombChance, 0.20);
  });

  test('surge weights sum to 1.0 for every stage', () {
    for (final s in [kCalm, kBrisk, kFrenzy]) {
      final sum = s.surgeLetterWeight + s.surgeBombWeight + s.surgeBothWeight;
      expect(sum, closeTo(1.0, 1e-9), reason: s.name);
    }
  });

  test('Brisk surge params match spec', () {
    expect(kBrisk.surgeCadence, 10.0);
    expect(kBrisk.surgeCount, 5);
    expect(kBrisk.surgeLetterWeight, 0.55);
    expect(kBrisk.surgeBombWeight, 0.25);
    expect(kBrisk.surgeBothWeight, 0.20);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/difficulty_curve_test.dart`
Expected: FAIL — `stageFor`/`Stage`/`kCalm` undefined (compile error).

- [ ] **Step 3: Write minimal implementation**

Replace the entire contents of `lib/core/difficulty_curve.dart` with:

```dart
/// Score-driven difficulty model for v2. Supersedes the v1 time-based ramp.
/// A [Stage] carries every per-stage spawning parameter; [stageFor] maps the
/// current score to its stage. Pure Dart — no Flame/Flutter dependency.
class Stage {
  const Stage({
    required this.name,
    required this.baselineInterval,
    required this.batchMin,
    required this.batchMax,
    required this.letterSpeed,
    required this.bombChance,
    required this.surgeCadence,
    required this.surgeCount,
    required this.surgeLetterWeight,
    required this.surgeBombWeight,
    required this.surgeBothWeight,
  });

  /// Display/debug name: 'Calm' | 'Brisk' | 'Frenzy'.
  final String name;

  /// Seconds between baseline spawn ticks.
  final double baselineInterval;

  /// Inclusive range of letters/bombs emitted per baseline tick.
  final int batchMin;
  final int batchMax;

  /// Multiplier on the spawn arc's vertical launch speed.
  final double letterSpeed;

  /// Chance a given baseline spawn is a bomb instead of a letter.
  final double bombChance;

  /// Seconds between surge rolls while in this stage.
  final double surgeCadence;

  /// Items emitted by one surge.
  final int surgeCount;

  /// Surge-type probability weights (sum to 1.0).
  final double surgeLetterWeight;
  final double surgeBombWeight;
  final double surgeBothWeight;
}

const kCalm = Stage(
  name: 'Calm',
  baselineInterval: 1.10,
  batchMin: 1,
  batchMax: 1,
  letterSpeed: 1.00,
  bombChance: 0.05,
  surgeCadence: 12.0,
  surgeCount: 3,
  surgeLetterWeight: 0.80,
  surgeBombWeight: 0.10,
  surgeBothWeight: 0.10,
);

const kBrisk = Stage(
  name: 'Brisk',
  baselineInterval: 0.80,
  batchMin: 1,
  batchMax: 2,
  letterSpeed: 1.15,
  bombChance: 0.12,
  surgeCadence: 10.0,
  surgeCount: 5,
  surgeLetterWeight: 0.55,
  surgeBombWeight: 0.25,
  surgeBothWeight: 0.20,
);

const kFrenzy = Stage(
  name: 'Frenzy',
  baselineInterval: 0.55,
  batchMin: 2,
  batchMax: 3,
  letterSpeed: 1.30,
  bombChance: 0.20,
  surgeCadence: 8.0,
  surgeCount: 8,
  surgeLetterWeight: 0.35,
  surgeBombWeight: 0.35,
  surgeBothWeight: 0.30,
);

/// Maps the current [score] to its difficulty [Stage].
Stage stageFor(int score) {
  if (score < 300) return kCalm;
  if (score < 900) return kBrisk;
  return kFrenzy;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/difficulty_curve_test.dart`
Expected: PASS (all 7 tests).

- [ ] **Step 5: Verify analyzer clean, then commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/core/difficulty_curve.dart test/core/difficulty_curve_test.dart
git commit -m "feat: score-driven Stage model replaces time-based difficulty curve"
```

> NOTE: After this task `lib/game/spawner.dart` will NOT compile (it still calls the removed `DifficultyCurve`). That is expected and is fixed in Task 3. Do not run the full suite until Task 3. The per-file commands above are sufficient for this task.

---

### Task 2: Combo-multiplier scoring

Switch `ScoreState` from "+10 per hit, +5/letter bonus over a 3-hit swipe" to "score the whole swipe at endSwipe as `10 × cuts × min(cuts, 4)`". Scoring now lands when the finger lifts (the multiplier applies to the whole swipe, so it cannot be computed per-hit). `comboThreshold` stays — `AlaifGame.endSwipe` uses it for the visual combo callout.

**Files:**
- Modify: `lib/core/score_state.dart`
- Modify (full rewrite): `test/core/score_state_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (unchanged public API except scoring semantics): `ScoreState` with `int get score`, `int get hitsInSwipe`, `int get bestCombo`, `void registerHit()`, `void endSwipe()`, `void reset()`, `static const int pointsPerLetter = 10`, `static const int comboThreshold = 3`, `static const int comboMultiplierCap = 4`, and `static int swipePoints(int cuts)`.

- [ ] **Step 1: Write the failing test**

Replace the entire contents of `test/core/score_state_test.dart` with:

```dart
import 'package:alaif/core/score_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('swipePoints formula: 10 * cuts * min(cuts, 4)', () {
    expect(ScoreState.swipePoints(1), 10);
    expect(ScoreState.swipePoints(2), 40);
    expect(ScoreState.swipePoints(3), 90);
    expect(ScoreState.swipePoints(4), 160);
    expect(ScoreState.swipePoints(5), 200);
    expect(ScoreState.swipePoints(6), 240);
    expect(ScoreState.swipePoints(0), 0);
  });

  test('score updates only at endSwipe (whole-swipe multiplier)', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    expect(state.score, 0); // nothing banked mid-swipe
    state.endSwipe();
    expect(state.score, 40); // 10 * 2 * 2
  });

  test('single-cut swipe scores 10', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
    expect(state.score, 10);
  });

  test('multiplier caps at x4', () {
    final state = ScoreState();
    for (var i = 0; i < 5; i++) {
      state.registerHit();
    }
    state.endSwipe();
    expect(state.score, 200); // 10 * 5 * 4
  });

  test('scores accumulate across swipes', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.endSwipe(); // +40
    state.registerHit();
    state.endSwipe(); // +10
    expect(state.score, 50);
  });

  test('endSwipe resets the per-swipe counter', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
    expect(state.hitsInSwipe, 0);
  });

  test('bestCombo records the largest chain of the run', () {
    final state = ScoreState();
    expect(state.bestCombo, 0);
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 1);
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 3);
    state.registerHit();
    state.endSwipe();
    expect(state.bestCombo, 3);
  });

  test('reset zeroes everything', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    state.reset();
    expect(state.score, 0);
    expect(state.hitsInSwipe, 0);
    expect(state.bestCombo, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/score_state_test.dart`
Expected: FAIL — `swipePoints` undefined and `score == 0` mid-swipe assertions fail under old logic.

- [ ] **Step 3: Write minimal implementation**

Replace the entire contents of `lib/core/score_state.dart` with:

```dart
import 'dart:math';

class ScoreState {
  static const pointsPerLetter = 10;

  /// Minimum hits in one swipe to trigger the combo callout/dust (visual only).
  static const comboThreshold = 3;

  /// The swipe multiplier is capped at this many cuts.
  static const comboMultiplierCap = 4;

  int _score = 0;
  int _hitsInSwipe = 0;
  int _bestCombo = 0;

  int get score => _score;
  int get hitsInSwipe => _hitsInSwipe;

  /// Largest chain (hits in a single swipe) seen this run.
  int get bestCombo => _bestCombo;

  /// Points awarded for a swipe of [cuts] letters: 10 * cuts * min(cuts, 4).
  static int swipePoints(int cuts) =>
      pointsPerLetter * cuts * min(cuts, comboMultiplierCap);

  void registerHit() {
    _hitsInSwipe += 1;
  }

  void endSwipe() {
    if (_hitsInSwipe > _bestCombo) _bestCombo = _hitsInSwipe;
    _score += swipePoints(_hitsInSwipe);
    _hitsInSwipe = 0;
  }

  void reset() {
    _score = 0;
    _hitsInSwipe = 0;
    _bestCombo = 0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/score_state_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

> Do not run the full suite yet — `spawner.dart` is still broken from Task 1; Task 3 restores it. The per-file run above is sufficient.

```bash
git add lib/core/score_state.dart test/core/score_state_test.dart
git commit -m "feat: combo-multiplier scoring (10 x cuts x min(cuts,4))"
```

---

### Task 3: Stage-driven Spawner (batch + concurrency cap + speed multiplier)

Rework `Spawner` to read the current `Stage` each tick from `game.scoreState.score`, emit a stage-scaled batch, scale launch speed by `stage.letterSpeed`, and refuse to exceed the concurrency cap. Extract a public `spawnItem` so the surge scheduler (Task 4) reuses the exact same arc/letter/bomb construction.

**Files:**
- Modify (full rewrite): `lib/game/spawner.dart`
- Modify (full rewrite): `test/game/spawner_test.dart`

**Interfaces:**
- Consumes: `stageFor`, `Stage` (Task 1); `game.scoreState.score`; `game.atlas`, `game.size` (existing `AlaifGame`).
- Produces:
  - `Spawner` component with `Spawner({Random? random})`.
  - `static const int maxConcurrentItems = 12`.
  - `bool get atCapacity` — true when on-screen letters + bombs ≥ `maxConcurrentItems`.
  - `void spawnItem({required bool bomb, required double speedMultiplier})` — adds one `LetterComponent` or `BombComponent` on an arc whose vertical speed is scaled by `speedMultiplier`. (Used by `SurgeScheduler` in Task 4.)

- [ ] **Step 1: Write the failing test**

Replace the entire contents of `test/game/spawner_test.dart` with:

```dart
import 'dart:math';

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/spawner.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  int liveItems(AlaifGame game) =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  /// Replaces the auto-installed spawner with a seeded one so spawns are
  /// deterministic, and returns it.
  Spawner reseed(AlaifGame game, int seed) {
    game.startGame();
    game.update(0);
    game.children
        .whereType<Spawner>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.update(0);
    final spawner = Spawner(random: Random(seed));
    game.add(spawner);
    game.update(0); // mount
    return spawner;
  }

  testWithGame<AlaifGame>('spawner emits items over time', AlaifGame.new,
      (game) async {
    reseed(game, 42);
    for (var i = 0; i < 30; i++) {
      game.update(0.1);
    }
    expect(liveItems(game), greaterThan(0));
  });

  testWithGame<AlaifGame>('startGame installs exactly one spawner',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<Spawner>().length, 1);
  });

  testWithGame<AlaifGame>('spawnItem adds a bomb when bomb: true',
      AlaifGame.new, (game) async {
    final spawner = reseed(game, 1);
    spawner.spawnItem(bomb: true, speedMultiplier: 1.0);
    game.update(0);
    expect(game.children.whereType<BombComponent>().length, 1);
    expect(game.children.whereType<LetterComponent>().length, 0);
  });

  testWithGame<AlaifGame>('spawnItem adds a letter when bomb: false',
      AlaifGame.new, (game) async {
    final spawner = reseed(game, 1);
    spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
    game.update(0);
    expect(game.children.whereType<LetterComponent>().length, 1);
    expect(game.children.whereType<BombComponent>().length, 0);
  });

  testWithGame<AlaifGame>('atCapacity true once at the cap', AlaifGame.new,
      (game) async {
    final spawner = reseed(game, 1);
    expect(spawner.atCapacity, isFalse);
    for (var i = 0; i < Spawner.maxConcurrentItems; i++) {
      spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
      game.update(0);
    }
    expect(liveItems(game), Spawner.maxConcurrentItems);
    expect(spawner.atCapacity, isTrue);
  });

  testWithGame<AlaifGame>('baseline never exceeds the concurrency cap',
      AlaifGame.new, (game) async {
    reseed(game, 7);
    // Long run; baseline must keep emitting but stay capped.
    for (var i = 0; i < 400; i++) {
      game.update(0.1);
    }
    expect(liveItems(game), lessThanOrEqualTo(Spawner.maxConcurrentItems));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/spawner_test.dart`
Expected: FAIL — `spawnItem` / `atCapacity` / `maxConcurrentItems` undefined; file also won't compile until Step 3.

- [ ] **Step 3: Write minimal implementation**

Replace the entire contents of `lib/game/spawner.dart` with:

```dart
import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';

/// Baseline spawner. Each tick it reads the current [Stage] from the live
/// score and emits a stage-scaled batch, never exceeding [maxConcurrentItems].
class Spawner extends Component with HasGameReference<AlaifGame> {
  Spawner({Random? random}) : _random = random ?? Random();

  /// Fairness/readability cap: letters + bombs on screen at once.
  static const maxConcurrentItems = 12;

  final Random _random;
  double _untilNext = 0.5; // quick first spawn; thereafter the stage governs

  int get _liveCount =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  bool get atCapacity => _liveCount >= maxConcurrentItems;

  @override
  void update(double dt) {
    if (!game.isPlaying) return;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      final stage = stageFor(game.scoreState.score);
      _spawnBatch(stage);
      _untilNext = stage.baselineInterval;
    }
  }

  void _spawnBatch(Stage stage) {
    final span = stage.batchMax - stage.batchMin + 1;
    final count = stage.batchMin + _random.nextInt(span);
    for (var i = 0; i < count; i++) {
      if (atCapacity) break;
      final bomb = _random.nextDouble() < stage.bombChance;
      spawnItem(bomb: bomb, speedMultiplier: stage.letterSpeed);
    }
  }

  /// Emits one item on a launch arc. [speedMultiplier] scales the vertical
  /// launch speed (stage letter-speed for baseline; boosted for surges).
  void spawnItem({required bool bomb, required double speedMultiplier}) {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    // Drift toward screen center; apex lands at 70–95% of screen height.
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy =
        -screen.y * (0.877 + 0.145 * _random.nextDouble()) * speedMultiplier;
    final motion = ArcMotion(
      start: start,
      velocity: Vector2(vx, vy),
      gravity: screen.y * 0.55,
    );

    if (bomb) {
      game.add(BombComponent(motion: motion));
    } else {
      final letter =
          GlyphAtlas.letters[_random.nextInt(GlyphAtlas.letters.length)];
      final targetSize = AlaifGlyph.spawnSizeMin +
          (AlaifGlyph.spawnSizeMax - AlaifGlyph.spawnSizeMin) *
              _random.nextDouble();
      game.add(LetterComponent(
        letter: letter,
        image: game.atlas.imageFor(letter),
        motion: motion,
        targetSize: targetSize,
        random: _random,
      ));
    }
  }
}
```

- [ ] **Step 4: Run the spawner test, then the FULL suite**

Run: `flutter test test/game/spawner_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: ALL tests pass. (Tasks 1–2 left the tree non-compiling; it compiles again now. If any unrelated test references removed `DifficultyCurve` symbols or old scoring constants, fix that test to the new API — search with `grep -rn "DifficultyCurve\|comboBonusPerLetter\|spawnInterval\|bombChance(" lib test` and update call sites.)

- [ ] **Step 5: Verify analyzer clean, then commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/game/spawner.dart test/game/spawner_test.dart
git commit -m "feat: stage-driven batch spawner with concurrency cap and speed multiplier"
```

---

### Task 4: SurgeScheduler component

A new component that, while playing, rolls a surge on the current stage's cadence, picks a type by the stage's weights, then emits `surgeCount` rapid sub-spawns (~0.15s apart) at a boosted arc speed via `Spawner.spawnItem`. Honors the concurrency cap (skips an item when at capacity).

**Files:**
- Create: `lib/game/surge_scheduler.dart`
- Create: `test/game/surge_scheduler_test.dart`

**Interfaces:**
- Consumes: `stageFor`, `Stage` (Task 1); `Spawner.spawnItem`, `Spawner.atCapacity` (Task 3); `game.scoreState.score`, `game.isPlaying`.
- Produces:
  - `SurgeScheduler` component with `SurgeScheduler({Random? random})`.
  - `static const double subSpawnInterval = 0.15`.
  - `static const double arcSpeedBoost = 1.25`.
  - `enum SurgeType { letter, bomb, both }`.

- [ ] **Step 1: Write the failing test**

Create `test/game/surge_scheduler_test.dart`:

```dart
import 'dart:math';

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/spawner.dart';
import 'package:alaif/game/surge_scheduler.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  int liveItems(AlaifGame game) =>
      game.children.whereType<LetterComponent>().length +
      game.children.whereType<BombComponent>().length;

  /// Starts the game, removes the baseline spawner (so only the surge under
  /// test produces items), and installs a seeded scheduler + seeded spawner.
  SurgeScheduler isolateSurge(AlaifGame game, int seed) {
    game.startGame();
    game.update(0);
    game.children
        .whereType<Spawner>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.children
        .whereType<SurgeScheduler>()
        .toList()
        .forEach((s) => s.removeFromParent());
    game.update(0);
    game.add(Spawner(random: Random(seed)));
    final scheduler = SurgeScheduler(random: Random(seed));
    game.add(scheduler);
    game.update(0); // mount both
    return scheduler;
  }

  testWithGame<AlaifGame>('no surge before the first cadence elapses',
      AlaifGame.new, (game) async {
    isolateSurge(game, 3);
    game.update(1.0); // Calm cadence is 12s; well short
    expect(liveItems(game), 0);
  });

  testWithGame<AlaifGame>('a surge fires after the cadence and emits items',
      AlaifGame.new, (game) async {
    isolateSurge(game, 3);
    game.update(12.0); // reach the Calm cadence -> start surge
    // Drive the sub-spawn timer; Calm surgeCount is 3 at 0.15s apart.
    for (var i = 0; i < 5; i++) {
      game.update(0.15);
    }
    expect(liveItems(game), greaterThan(0));
    expect(liveItems(game), lessThanOrEqualTo(3));
  });

  testWithGame<AlaifGame>('surge respects the concurrency cap', AlaifGame.new,
      (game) async {
    final scheduler = isolateSurge(game, 9);
    // Pre-fill to the cap via the spawner.
    final spawner = game.children.whereType<Spawner>().first;
    for (var i = 0; i < Spawner.maxConcurrentItems; i++) {
      spawner.spawnItem(bomb: false, speedMultiplier: 1.0);
      game.update(0);
    }
    expect(scheduler.isMounted, isTrue);
    game.update(12.0);
    for (var i = 0; i < 10; i++) {
      game.update(0.15);
    }
    expect(liveItems(game), lessThanOrEqualTo(Spawner.maxConcurrentItems));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/surge_scheduler_test.dart`
Expected: FAIL — `surge_scheduler.dart` / `SurgeScheduler` does not exist (compile error).

- [ ] **Step 3: Write minimal implementation**

Create `lib/game/surge_scheduler.dart`:

```dart
import 'dart:math';

import 'package:flame/components.dart';

import '../core/difficulty_curve.dart';
import 'alaif_game.dart';
import 'spawner.dart';

enum SurgeType { letter, bomb, both }

/// Layers timed surge bursts on top of baseline spawning. On each stage's
/// cadence it rolls a [SurgeType] by the stage weights, then emits
/// [Stage.surgeCount] sub-spawns [subSpawnInterval] apart at a boosted arc
/// speed, delegating actual spawning to the [Spawner].
class SurgeScheduler extends Component with HasGameReference<AlaifGame> {
  SurgeScheduler({Random? random}) : _random = random ?? Random();

  /// Seconds between sub-spawns within a single surge.
  static const subSpawnInterval = 0.15;

  /// Extra arc-speed multiplier on top of the stage letter-speed, so a surge
  /// reads as a distinct rush rather than a faster trickle.
  static const arcSpeedBoost = 1.25;

  final Random _random;

  double _untilNext = 0; // set on mount to the current stage cadence
  int _remaining = 0; // sub-spawns left in the active surge
  double _subTimer = 0;
  SurgeType _type = SurgeType.letter;

  @override
  void onMount() {
    super.onMount();
    _untilNext = stageFor(game.scoreState.score).surgeCadence;
  }

  @override
  void update(double dt) {
    if (!game.isPlaying) return;
    final stage = stageFor(game.scoreState.score);

    if (_remaining > 0) {
      _subTimer -= dt;
      while (_remaining > 0 && _subTimer <= 0) {
        _emitOne(stage);
        _remaining -= 1;
        _subTimer += subSpawnInterval;
      }
      return;
    }

    _untilNext -= dt;
    if (_untilNext <= 0) {
      _startSurge(stage);
    }
  }

  void _startSurge(Stage stage) {
    _remaining = stage.surgeCount;
    _subTimer = 0;
    _type = _rollType(stage);
    _untilNext = stage.surgeCadence;
  }

  SurgeType _rollType(Stage stage) {
    final roll = _random.nextDouble();
    if (roll < stage.surgeLetterWeight) return SurgeType.letter;
    if (roll < stage.surgeLetterWeight + stage.surgeBombWeight) {
      return SurgeType.bomb;
    }
    return SurgeType.both;
  }

  void _emitOne(Stage stage) {
    final spawners = game.children.whereType<Spawner>();
    if (spawners.isEmpty) return;
    final spawner = spawners.first;
    if (spawner.atCapacity) return; // gated; drop this item
    final bomb = switch (_type) {
      SurgeType.letter => false,
      SurgeType.bomb => true,
      SurgeType.both => _random.nextDouble() < 0.5,
    };
    spawner.spawnItem(
      bomb: bomb,
      speedMultiplier: stage.letterSpeed * arcSpeedBoost,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/surge_scheduler_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Verify analyzer clean, then commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/game/surge_scheduler.dart test/game/surge_scheduler_test.dart
git commit -m "feat: SurgeScheduler emits timed, type-rolled spawn bursts"
```

---

### Task 5: Wire SurgeScheduler into the game lifecycle

`AlaifGame.startGame` must install a `SurgeScheduler` alongside the `Spawner`, and both the start-game reset and `quitToMenu` cleanup must remove it (so a new run starts fresh and an abandoned run leaves nothing scheduling). This is the integration step.

**Files:**
- Modify: `lib/game/alaif_game.dart` (import; `startGame` cleanup filter + add; `quitToMenu` cleanup filter)
- Modify: `test/game/alaif_game_test.dart` (add lifecycle tests)

**Interfaces:**
- Consumes: `SurgeScheduler` (Task 4); existing `AlaifGame.startGame`, `AlaifGame.quitToMenu`.
- Produces: a running game that has exactly one `SurgeScheduler` while playing and zero after `quitToMenu`.

- [ ] **Step 1: Write the failing test**

Append these tests inside the existing `main()` of `test/game/alaif_game_test.dart` (keep all existing tests). If the file lacks the imports below, add them to the top import block:

```dart
import 'package:alaif/game/surge_scheduler.dart';
```

Tests to add (place before the closing `}` of `main`):

```dart
  testWithGame<AlaifGame>('startGame installs exactly one SurgeScheduler',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<SurgeScheduler>().length, 1);
  });

  testWithGame<AlaifGame>('quitToMenu removes the SurgeScheduler',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    expect(game.children.whereType<SurgeScheduler>().length, 1);
    game.quitToMenu();
    game.update(0);
    expect(game.children.whereType<SurgeScheduler>().length, 0);
  });
```

> If `test/game/alaif_game_test.dart` does not already import `flame_test`/`AlaifGame`/`shared_preferences` or set up `SharedPreferences.setMockInitialValues({})` in `setUp`, mirror the setup used in `test/game/spawner_test.dart`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/alaif_game_test.dart`
Expected: FAIL — no `SurgeScheduler` is added (count 0, not 1).

- [ ] **Step 3: Write minimal implementation**

In `lib/game/alaif_game.dart`:

3a. Add the import next to the other `game/` imports (after `import 'spawner.dart';`):

```dart
import 'surge_scheduler.dart';
```

3b. In `startGame`, the children-cleanup filter currently lists `LetterComponent | BombComponent | SlicedHalf | Spawner`. Add `SurgeScheduler`. Replace:

```dart
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner)
        .toList()
        .forEach((c) => c.removeFromParent());
    add(Spawner());
```

with:

```dart
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner ||
            c is SurgeScheduler)
        .toList()
        .forEach((c) => c.removeFromParent());
    add(Spawner());
    add(SurgeScheduler());
```

3c. In `quitToMenu`, the same cleanup filter appears again. Replace:

```dart
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner)
        .toList()
        .forEach((c) => c.removeFromParent());
```

with:

```dart
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner ||
            c is SurgeScheduler)
        .toList()
        .forEach((c) => c.removeFromParent());
```

- [ ] **Step 4: Run the file test, then the FULL suite**

Run: `flutter test test/game/alaif_game_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: ALL tests pass.

- [ ] **Step 5: Verify analyzer clean, then commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/game/alaif_game.dart test/game/alaif_game_test.dart
git commit -m "feat: wire SurgeScheduler into game start/quit lifecycle"
```

---

## Final verification

- [ ] Run the entire suite once more: `flutter test` — all green.
- [ ] `flutter analyze` — `No issues found!`.
- [ ] Manual smoke (optional, on simulator/device): `flutter run` — confirm letters appear singly early (Calm), multi-letter batches and faster arcs after score climbs, and periodic surges of letters/bombs/both.
- [ ] Update `wiki/log.md` with an execution entry and `wiki/index.md` to mark this plan ✅ Executed.

## Spec coverage check

- Score-driven discrete stages → Task 1 (`stageFor`, three `Stage`s).
- Faster/denser as score climbs (interval, batch, speed, bomb%) → Task 1 params + Task 3 baseline.
- Multiple letters at once → Task 3 `_spawnBatch`.
- Surges (letter/bomb/both, escalating weights, 3→8 count, ~0.15s sub-spawns, faster arc) → Task 4.
- Combo multiplier `10×cuts×min(cuts,4)` → Task 2.
- Cap (interval floor 0.55s = Frenzy value; ~12 concurrent; surges gated) → Task 1 + Task 3 `atCapacity` + Task 4 gate.
- Lifecycle integration → Task 5.

See [[difficulty-design]] for the grounding spec.
