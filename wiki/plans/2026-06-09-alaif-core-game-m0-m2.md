# Alaif Core Game (M0–M2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable offline Classic mode: Arabic letters arc across the screen, swipes slice them into tumbling halves, with scoring, combos, bombs, lives, game over, and a persisted local high score.

**Architecture:** Flutter shell (overlays for menu/pause/game-over) + a single `FlameGame` containing Spawner, LetterComponent, BombComponent, SlicedHalf, BladeTrail, and HUD components. All game math (arcs, hit tests, scoring, rules, difficulty) lives in pure-logic classes under `lib/core/` so it is unit-testable without Flame. Spec: `wiki/alaif-v1-design.md`. Covers milestones M0–M2; M3–M5 (juice, polish, store prep) are separate future plans.

**Tech Stack:** Flutter (stable channel), Flame (`flame`), `shared_preferences`, `flame_test` + `flutter_test` for tests.

---

## File Structure

All paths relative to repo root. The Flutter project lives in `app/`.

```
app/
  lib/
    main.dart                    # App entry, GameWidget + overlay map
    core/                        # Pure logic, no Flame components
      arc_motion.dart            # Gravity-arc position math
      hit_test.dart              # Segment-vs-circle intersection
      trail_buffer.dart          # Time-windowed swipe point buffer
      score_state.dart           # Score + combo accounting
      game_rules.dart            # Lives / game-over rules
      difficulty_curve.dart      # Spawn interval + bomb chance over time
      glyph_atlas.dart           # Pre-renders 28 letters to ui.Image textures
    game/                        # Flame components
      alaif_game.dart            # FlameGame: state, slicing, missed letters, game over
      letter_component.dart      # Flying glyph
      bomb_component.dart        # Flying bomb
      sliced_halves.dart         # Clipped half-glyph tumbling away
      blade_trail.dart           # Drag input + glowing trail + slice dispatch
      spawner.dart               # Timed letter/bomb emission
      hud.dart                   # Score + lives text
    services/
      high_score_store.dart      # shared_preferences persistence
    ui/
      menu_overlay.dart          # Title + Play + best score
      game_over_overlay.dart     # Score + Play Again
      pause_overlay.dart         # Resume button
  test/
    core/   (one test file per core class)
    game/   (alaif_game_test.dart, spawner_test.dart, components_test.dart)
    services/high_score_store_test.dart
    ui/overlays_test.dart
```

**Conventions for every task below:** run all commands from `app/`. Commit messages use conventional commits. After each task's tests pass, also run `flutter analyze` and fix any warnings in files you touched before committing.

---

### Task 1: Scaffold the Flutter project (M0)

**Files:**
- Create: `app/` Flutter project (in place — `app/CLAUDE.md` already exists and must survive)
- Modify: `app/pubspec.yaml` (via `flutter pub add`)
- Delete: `app/test/widget_test.dart` (counter-app default, irrelevant)

- [ ] **Step 1: Create the project in the existing `app/` directory**

```bash
cd app
flutter create . --project-name alaif --org com.alaif --platforms ios,android
```

Expected: project files generated; `CLAUDE.md` untouched.

- [ ] **Step 2: Add dependencies**

```bash
flutter pub add flame shared_preferences
flutter pub add dev:flame_test
```

Expected: pubspec updated, `flutter pub get` succeeds.

- [ ] **Step 3: Remove the default counter test and strip `lib/main.dart` to a placeholder**

```bash
rm test/widget_test.dart
```

Replace `lib/main.dart` entirely with:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const Placeholder());
}
```

(Real app shell arrives in Task 14.)

- [ ] **Step 4: Verify the toolchain**

Run: `flutter analyze && flutter test`
Expected: analyze passes; test reports "No tests ran" (exit 0) or trivially passes.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: scaffold Flutter project with flame and shared_preferences"
```

---

### Task 2: ArcMotion (M0)

**Files:**
- Create: `app/lib/core/arc_motion.dart`
- Test: `app/test/core/arc_motion_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at start position', () {
    final motion = ArcMotion(start: Vector2(10, 20), velocity: Vector2(0, -100));
    expect(motion.positionAt(0), Vector2(10, 20));
  });

  test('rises then falls under gravity', () {
    final motion =
        ArcMotion(start: Vector2(0, 0), velocity: Vector2(0, -100), gravity: 100);
    expect(motion.positionAt(1).y, lessThan(0)); // above start (y is down)
    expect(motion.positionAt(3).y, greaterThan(motion.positionAt(1).y)); // falling
  });

  test('moves horizontally at constant speed', () {
    final motion =
        ArcMotion(start: Vector2(0, 0), velocity: Vector2(50, 0), gravity: 0);
    expect(motion.positionAt(2).x, 100);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/arc_motion_test.dart`
Expected: FAIL — compilation error, `arc_motion.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flame/components.dart';

/// Projectile motion: constant horizontal velocity, gravity pulls +y (down).
class ArcMotion {
  ArcMotion({required Vector2 start, required Vector2 velocity, this.gravity = 900})
      : _start = start.clone(),
        _velocity = velocity.clone();

  final Vector2 _start;
  final Vector2 _velocity;
  final double gravity;

  Vector2 positionAt(double t) => Vector2(
        _start.x + _velocity.x * t,
        _start.y + _velocity.y * t + 0.5 * gravity * t * t,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/arc_motion_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/arc_motion.dart test/core/arc_motion_test.dart
git commit -m "feat: add ArcMotion gravity-arc math"
```

---

### Task 3: Segment-vs-circle hit test (M0)

**Files:**
- Create: `app/lib/core/hit_test.dart`
- Test: `app/test/core/hit_test_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/hit_test.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('segment crossing the circle hits', () {
    expect(
      segmentHitsCircle(Vector2(0, 50), Vector2(100, 50), Vector2(50, 50), 10),
      isTrue,
    );
  });

  test('segment far from the circle misses', () {
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(100, 0), Vector2(50, 50), 10),
      isFalse,
    );
  });

  test('closest point clamps to segment endpoints', () {
    // Circle sits beyond the end of the segment, just out of reach.
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(25, 0), 10),
      isFalse,
    );
    // ...and just within reach of the endpoint.
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(19, 0), 10),
      isTrue,
    );
  });

  test('zero-length segment acts as a point', () {
    expect(
      segmentHitsCircle(Vector2(5, 5), Vector2(5, 5), Vector2(5, 8), 10),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/hit_test_test.dart`
Expected: FAIL — `hit_test.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flame/components.dart';

/// True if the segment [a]→[b] passes within [radius] of [center].
bool segmentHitsCircle(Vector2 a, Vector2 b, Vector2 center, double radius) {
  final ab = b - a;
  final len2 = ab.length2;
  final t = len2 == 0 ? 0.0 : ((center - a).dot(ab) / len2).clamp(0.0, 1.0);
  final closest = a + ab * t;
  return closest.distanceToSquared(center) <= radius * radius;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/hit_test_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/hit_test.dart test/core/hit_test_test.dart
git commit -m "feat: add segment-vs-circle hit test"
```

---

### Task 4: TrailBuffer (M0)

**Files:**
- Create: `app/lib/core/trail_buffer.dart`
- Test: `app/test/core/trail_buffer_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/trail_buffer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps recent points', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.00);
    buffer.add(Vector2(1, 1), 1.05);
    expect(buffer.points.length, 2);
  });

  test('prunes points older than maxAge', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.00);
    buffer.add(Vector2(1, 1), 1.05);
    buffer.prune(1.20);
    expect(buffer.points, isEmpty);
  });

  test('clear empties the buffer', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.0);
    buffer.clear();
    expect(buffer.points, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/trail_buffer_test.dart`
Expected: FAIL — `trail_buffer.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'package:flame/components.dart';

class TrailPoint {
  TrailPoint(this.position, this.time);
  final Vector2 position;
  final double time;
}

/// Holds the last [maxAge] seconds of swipe points.
class TrailBuffer {
  TrailBuffer({this.maxAge = 0.1});

  final double maxAge;
  final List<TrailPoint> _points = [];

  List<TrailPoint> get points => List.unmodifiable(_points);

  void add(Vector2 position, double time) {
    _points.add(TrailPoint(position.clone(), time));
    prune(time);
  }

  void prune(double now) {
    _points.removeWhere((p) => now - p.time > maxAge);
  }

  void clear() => _points.clear();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/trail_buffer_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/trail_buffer.dart test/core/trail_buffer_test.dart
git commit -m "feat: add time-windowed TrailBuffer"
```

---

### Task 5: ScoreState (M2 logic, built early)

**Files:**
- Create: `app/lib/core/score_state.dart`
- Test: `app/test/core/score_state_test.dart`

Scoring rules (from spec): 10 points per letter; a swipe slicing 3+ letters is a combo worth a bonus of 5 points per letter in the swipe, granted when the swipe ends.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/score_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each hit scores pointsPerLetter', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    expect(state.score, 2 * ScoreState.pointsPerLetter);
  });

  test('no combo bonus for fewer than 3 hits in a swipe', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    expect(state.score, 2 * ScoreState.pointsPerLetter);
  });

  test('combo bonus for 3+ hits in a swipe', () {
    final state = ScoreState();
    for (var i = 0; i < 3; i++) {
      state.registerHit();
    }
    state.endSwipe();
    expect(state.score,
        3 * ScoreState.pointsPerLetter + 3 * ScoreState.comboBonusPerLetter);
  });

  test('endSwipe resets the per-swipe counter', () {
    final state = ScoreState();
    state.registerHit();
    state.endSwipe();
    expect(state.hitsInSwipe, 0);
  });

  test('reset zeroes everything', () {
    final state = ScoreState();
    state.registerHit();
    state.reset();
    expect(state.score, 0);
    expect(state.hitsInSwipe, 0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/score_state_test.dart`
Expected: FAIL — `score_state.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
class ScoreState {
  static const pointsPerLetter = 10;
  static const comboThreshold = 3;
  static const comboBonusPerLetter = 5;

  int _score = 0;
  int _hitsInSwipe = 0;

  int get score => _score;
  int get hitsInSwipe => _hitsInSwipe;

  void registerHit() {
    _hitsInSwipe += 1;
    _score += pointsPerLetter;
  }

  void endSwipe() {
    if (_hitsInSwipe >= comboThreshold) {
      _score += _hitsInSwipe * comboBonusPerLetter;
    }
    _hitsInSwipe = 0;
  }

  void reset() {
    _score = 0;
    _hitsInSwipe = 0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/score_state_test.dart`
Expected: 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/score_state.dart test/core/score_state_test.dart
git commit -m "feat: add ScoreState with swipe combos"
```

---

### Task 6: GameRules (M2 logic, built early)

**Files:**
- Create: `app/lib/core/game_rules.dart`
- Test: `app/test/core/game_rules_test.dart`

Rules (from spec): 3 lives; a missed letter costs a life; slicing a bomb costs a life; 0 lives = game over.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/game_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with 3 lives and not game over', () {
    final rules = GameRules();
    expect(rules.lives, 3);
    expect(rules.isGameOver, isFalse);
  });

  test('three missed letters end the game', () {
    final rules = GameRules();
    rules.onLetterMissed();
    rules.onLetterMissed();
    rules.onLetterMissed();
    expect(rules.isGameOver, isTrue);
  });

  test('slicing a bomb costs a life', () {
    final rules = GameRules();
    rules.onBombSliced();
    expect(rules.lives, 2);
  });

  test('reset restores lives', () {
    final rules = GameRules();
    rules.onBombSliced();
    rules.reset();
    expect(rules.lives, 3);
    expect(rules.isGameOver, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/game_rules_test.dart`
Expected: FAIL — `game_rules.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
class GameRules {
  static const startingLives = 3;

  int _lives = startingLives;

  int get lives => _lives;
  bool get isGameOver => _lives <= 0;

  void onLetterMissed() => _loseLife();
  void onBombSliced() => _loseLife();

  void _loseLife() {
    if (_lives > 0) _lives -= 1;
  }

  void reset() => _lives = startingLives;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/game_rules_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/game_rules.dart test/core/game_rules_test.dart
git commit -m "feat: add GameRules lives and game-over logic"
```

---

### Task 7: DifficultyCurve (M1)

**Files:**
- Create: `app/lib/core/difficulty_curve.dart`
- Test: `app/test/core/difficulty_curve_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/difficulty_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final curve = DifficultyCurve();

  test('spawn interval starts high and decreases', () {
    expect(curve.spawnInterval(0), DifficultyCurve.startInterval);
    expect(curve.spawnInterval(30), lessThan(curve.spawnInterval(0)));
  });

  test('spawn interval floors at minInterval', () {
    expect(curve.spawnInterval(9999), DifficultyCurve.minInterval);
  });

  test('bomb chance starts low and rises', () {
    expect(curve.bombChance(0), DifficultyCurve.startBombChance);
    expect(curve.bombChance(30), greaterThan(curve.bombChance(0)));
  });

  test('bomb chance caps at maxBombChance', () {
    expect(curve.bombChance(9999), DifficultyCurve.maxBombChance);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/difficulty_curve_test.dart`
Expected: FAIL — `difficulty_curve.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:math';

/// Linear ramp over [rampSeconds] of play time.
class DifficultyCurve {
  static const startInterval = 1.2;
  static const minInterval = 0.4;
  static const startBombChance = 0.05;
  static const maxBombChance = 0.2;
  static const rampSeconds = 90.0;

  double spawnInterval(double elapsed) {
    final t = min(elapsed / rampSeconds, 1.0);
    return startInterval - (startInterval - minInterval) * t;
  }

  double bombChance(double elapsed) {
    final t = min(elapsed / rampSeconds, 1.0);
    return startBombChance + (maxBombChance - startBombChance) * t;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/difficulty_curve_test.dart`
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/difficulty_curve.dart test/core/difficulty_curve_test.dart
git commit -m "feat: add DifficultyCurve spawn ramp"
```

---

### Task 8: GlyphAtlas — the M0 spike

**Files:**
- Create: `app/lib/core/glyph_atlas.dart`
- Test: `app/test/core/glyph_atlas_test.dart`

This is the riskiest piece (letter → texture), so it's proven here with tests before any component uses it. Flutter's `TextPainter` handles Arabic shaping natively; isolated letter forms avoid joining complexity. The gradient fill comes from the approved art direction. Font family is left at system default for M0–M2; a bundled calligraphic font is an M3/M4 concern (the `fontFamily` parameter is already in place for it).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/glyph_atlas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a single glyph to a non-empty image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  });

  test('atlas exposes all 28 letters', () {
    expect(GlyphAtlas.letters.length, 28);
    expect(GlyphAtlas.letters.toSet().length, 28); // no duplicates
  });

  test('load makes every letter available', () async {
    final atlas = GlyphAtlas();
    await atlas.load();
    for (final letter in GlyphAtlas.letters) {
      expect(atlas.imageFor(letter).width, greaterThan(0));
    }
  });

  test('imageFor throws before load', () {
    expect(() => GlyphAtlas().imageFor('ب'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/glyph_atlas_test.dart`
Expected: FAIL — `glyph_atlas.dart` not found.

- [ ] **Step 3: Write the implementation**

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to textures at load.
class GlyphAtlas {
  static const letters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
    'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
    'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  final Map<String, ui.Image> _images = {};

  ui.Image imageFor(String letter) {
    final image = _images[letter];
    if (image == null) {
      throw StateError('GlyphAtlas.load() must complete before imageFor("$letter")');
    }
    return image;
  }

  Future<void> load({double fontSize = 120, String? fontFamily}) async {
    for (final letter in letters) {
      _images[letter] =
          await renderGlyph(letter, fontSize: fontSize, fontFamily: fontFamily);
    }
  }

  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = 120,
    String? fontFamily,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final foreground = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, fontSize),
        const [Color(0xFFFFD97A), Color(0xFFFF9D3D)],
      );
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          foreground: foreground,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    painter.paint(canvas, Offset.zero);
    final width = math.max(1, painter.width.ceil());
    final height = math.max(1, painter.height.ceil());
    return recorder.endRecording().toImage(width, height);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/glyph_atlas_test.dart`
Expected: 4 tests PASS. (The test environment renders with the Ahem block font — dimensions still verify the pipeline.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/glyph_atlas.dart test/core/glyph_atlas_test.dart
git commit -m "feat: add GlyphAtlas letter-to-texture pipeline"
```

---

### Task 9: HighScoreStore (M2)

**Files:**
- Create: `app/lib/services/high_score_store.dart`
- Test: `app/test/services/high_score_store_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/services/high_score_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads 0 when nothing stored', () async {
    expect(await HighScoreStore().read(), 0);
  });

  test('submit stores a new high score', () async {
    final store = HighScoreStore();
    await store.submit(120);
    expect(await store.read(), 120);
  });

  test('submit ignores lower scores', () async {
    final store = HighScoreStore();
    await store.submit(120);
    await store.submit(50);
    expect(await store.read(), 120);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/high_score_store_test.dart`
Expected: FAIL — `high_score_store.dart` not found.

- [ ] **Step 3: Write the implementation**

Per the spec's error-handling section, persistence failures degrade to defaults rather than crashing the game.

```dart
import 'package:shared_preferences/shared_preferences.dart';

class HighScoreStore {
  static const _key = 'highScore';

  Future<int> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> submit(int score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (score > (prefs.getInt(_key) ?? 0)) {
        await prefs.setInt(_key, score);
      }
    } catch (_) {
      // A lost high score must never crash gameplay.
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/high_score_store_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/high_score_store.dart test/services/high_score_store_test.dart
git commit -m "feat: add HighScoreStore with shared_preferences"
```

---

### Task 10: Flying components — Letter, Bomb, SlicedHalf (M0/M1)

**Files:**
- Create: `app/lib/game/letter_component.dart`
- Create: `app/lib/game/bomb_component.dart`
- Create: `app/lib/game/sliced_halves.dart`
- Test: `app/test/game/components_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> testImage({int width = 40, int height = 60}) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(width, height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('letter follows its arc as time advances', () async {
    final image = await testImage();
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2(100, 500), velocity: Vector2(20, -300), gravity: 0),
    );
    expect(letter.position, Vector2(100, 500));
    letter.update(1.0);
    expect(letter.position, Vector2(120, 200));
  });

  test('letter hit radius derives from its size', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
    );
    expect(letter.hitRadius, 40);
  });

  test('sliced half falls and removes itself below the cutoff', () async {
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2(0, 100),
      topHalf: true,
      removeBelowY: 200,
    );
    half.update(0.5); // y ≈ 100 + ~50–70 (gravity adds speed)
    expect(half.position.y, greaterThan(100));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/components_test.dart`
Expected: FAIL — component files not found.

- [ ] **Step 3: Write `letter_component.dart`**

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
  }) : _image = image {
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  ui.Image get image => _image;
  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
    angle += 0.5 * dt; // gentle tumble
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawImage(_image, ui.Offset.zero, ui.Paint());
  }
}
```

- [ ] **Step 4: Write `bomb_component.dart`**

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';

class BombComponent extends PositionComponent {
  BombComponent({required this.motion}) {
    size = Vector2.all(80);
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  final ArcMotion motion;
  double _age = 0;
  bool entered = false;

  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, ui.Paint()..color = const ui.Color(0xFF1B1B1B));
    canvas.drawCircle(
      center,
      size.x / 2,
      ui.Paint()
        ..color = const ui.Color(0xFFFF4444)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}
```

- [ ] **Step 5: Write `sliced_halves.dart`**

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// One half of a sliced glyph, clipped from the full texture, tumbling away.
class SlicedHalf extends PositionComponent {
  SlicedHalf({
    required ui.Image image,
    required Vector2 startPosition,
    required Vector2 velocity,
    required this.topHalf,
    required this.removeBelowY,
  })  : _image = image,
        _velocity = velocity.clone() {
    size = Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = startPosition.clone();
  }

  static const gravity = 900.0;
  static const spin = 3.0;

  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;

  @override
  void update(double dt) {
    _velocity.y += gravity * dt;
    position += _velocity * dt;
    angle += (topHalf ? -spin : spin) * dt;
    if (position.y > removeBelowY) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final clip = topHalf
        ? ui.Rect.fromLTWH(0, 0, size.x, size.y / 2)
        : ui.Rect.fromLTWH(0, size.y / 2, size.x, size.y / 2);
    canvas.save();
    canvas.clipRect(clip);
    canvas.drawImage(_image, ui.Offset.zero, ui.Paint());
    canvas.restore();
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/game/components_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/game/letter_component.dart lib/game/bomb_component.dart lib/game/sliced_halves.dart test/game/components_test.dart
git commit -m "feat: add letter, bomb, and sliced-half components"
```

---

### Task 11: AlaifGame — slicing, misses, game over (M1+M2)

**Files:**
- Create: `app/lib/game/alaif_game.dart`
- Create: `app/lib/game/hud.dart`
- Test: `app/test/game/alaif_game_test.dart`

Note: `alaif_game.dart` references `BladeTrail` and `Spawner`, which arrive in Tasks 12–13. To keep this task self-contained and compiling, `startGame()` here only manages state and existing components; Spawner/BladeTrail/HUD are wired into `startGame()` in their own tasks.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LetterComponent staticLetter(AlaifGame game, {double x = 100, double y = 300}) {
  return LetterComponent(
    letter: 'ب',
    image: game.atlas.imageFor('ب'),
    motion: ArcMotion(start: Vector2(x, y), velocity: Vector2.zero(), gravity: 0),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('startGame resets score and lives', AlaifGame.new,
      (game) async {
    game.startGame();
    expect(game.isPlaying, isTrue);
    expect(game.scoreState.score, 0);
    expect(game.rules.lives, 3);
  });

  testWithGame<AlaifGame>('slicing a letter scores and spawns two halves',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0); // mount

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process removal/additions

    expect(game.scoreState.score, ScoreState.pointsPerLetter);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
    expect(game.children.whereType<SlicedHalf>().length, 2);
  });

  testWithGame<AlaifGame>('slicing a bomb costs a life', AlaifGame.new,
      (game) async {
    game.startGame();
    game.add(BombComponent(
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    ));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);

    expect(game.rules.lives, 2);
  });

  testWithGame<AlaifGame>('a letter falling offscreen after entering costs a life',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game, y: 300)..entered = true;
    game.add(letter);
    game.update(0);

    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.rules.lives, 2);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
  });

  testWithGame<AlaifGame>('losing all lives ends the game and shows overlay',
      AlaifGame.new, (game) async {
    game.startGame();
    game.rules.onBombSliced();
    game.rules.onBombSliced();

    final letter = staticLetter(game)..entered = true;
    game.add(letter);
    game.update(0);
    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.isPlaying, isFalse);
    expect(game.overlays.isActive('gameOver'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/alaif_game_test.dart`
Expected: FAIL — `alaif_game.dart` not found.

- [ ] **Step 3: Write `hud.dart`**

```dart
import 'package:flame/components.dart';

import 'alaif_game.dart';

class Hud extends TextComponent with HasGameReference<AlaifGame> {
  Hud() : super(position: Vector2(16, 48), priority: 90);

  @override
  void update(double dt) {
    text = 'Score ${game.scoreState.score}   Lives ${game.rules.lives}';
  }
}
```

- [ ] **Step 4: Write `alaif_game.dart`**

```dart
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
import 'sliced_halves.dart';

class AlaifGame extends FlameGame {
  AlaifGame({HighScoreStore? highScores})
      : highScores = highScores ?? HighScoreStore();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;

  bool _playing = false;
  bool get isPlaying => _playing;

  @override
  Color backgroundColor() => const Color(0xFF120C1D);

  @override
  Future<void> onLoad() async {
    await atlas.load();
    overlays.add('menu');
  }

  void startGame() {
    scoreState.reset();
    rules.reset();
    children
        .where((c) =>
            c is LetterComponent || c is BombComponent || c is SlicedHalf)
        .toList()
        .forEach((c) => c.removeFromParent());
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
  }

  /// Called by BladeTrail for each new swipe segment.
  void trySlice(Vector2 from, Vector2 to) {
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        _checkGameOver();
      }
    }
  }

  /// Called by BladeTrail when the finger lifts.
  void endSwipe() => scoreState.endSwipe();

  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    letter.removeFromParent();
    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(-120, -150),
      topHalf: true,
      removeBelowY: cutoff,
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(120, -100),
      topHalf: false,
      removeBelowY: cutoff,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (!letter.entered && letter.position.y < size.y) letter.entered = true;
      if (letter.entered && letter.position.y > size.y + 120) {
        letter.removeFromParent();
        rules.onLetterMissed();
        _checkGameOver();
      }
    }
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (!bomb.entered && bomb.position.y < size.y) bomb.entered = true;
      if (bomb.entered && bomb.position.y > size.y + 120) {
        bomb.removeFromParent(); // missing a bomb is free
      }
    }
  }

  void _checkGameOver() {
    if (!rules.isGameOver || !_playing) return;
    _playing = false;
    highScores.submit(scoreState.score);
    overlays.add('gameOver');
  }

  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    overlays.add('paused');
  }

  void resumeFromPause() {
    overlays.remove('paused');
    resumeEngine();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseGame();
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/game/alaif_game_test.dart`
Expected: 5 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/game/alaif_game.dart lib/game/hud.dart test/game/alaif_game_test.dart
git commit -m "feat: add AlaifGame slicing, lives, and game-over flow"
```

---

### Task 12: Spawner (M1)

**Files:**
- Create: `app/lib/game/spawner.dart`
- Modify: `app/lib/game/alaif_game.dart` (wire Spawner into `startGame`)
- Test: `app/test/game/spawner_test.dart`

- [ ] **Step 1: Write the failing test**

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

  testWithGame<AlaifGame>('spawner emits letters or bombs over time',
      AlaifGame.new, (game) async {
    game.add(Spawner(random: Random(42)));
    game.update(0); // mount

    // Advance well past the first spawn delay in small ticks.
    for (var i = 0; i < 30; i++) {
      game.update(0.1);
    }

    final flying = game.children.whereType<LetterComponent>().length +
        game.children.whereType<BombComponent>().length;
    expect(flying, greaterThan(0));
  });

  testWithGame<AlaifGame>('startGame installs exactly one spawner',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<Spawner>().length, 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/spawner_test.dart`
Expected: FAIL — `spawner.dart` not found.

- [ ] **Step 3: Write `spawner.dart`**

Launch velocities and gravity scale with screen height so arcs reach similar peaks on any device (spec: fairness across screen sizes).

```dart
import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';

class Spawner extends Component with HasGameReference<AlaifGame> {
  Spawner({Random? random}) : _random = random ?? Random();

  final Random _random;
  final DifficultyCurve _curve = DifficultyCurve();
  double _elapsed = 0;
  double _untilNext = 0.5;

  @override
  void update(double dt) {
    _elapsed += dt;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      _spawn();
      _untilNext = _curve.spawnInterval(_elapsed);
    }
  }

  void _spawn() {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    // Drift toward screen center; rise to roughly 70–95% of screen height.
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy = -screen.y * (0.95 + 0.25 * _random.nextDouble());
    final motion = ArcMotion(
      start: start,
      velocity: Vector2(vx, vy),
      gravity: screen.y * 0.55,
    );

    if (_random.nextDouble() < _curve.bombChance(_elapsed)) {
      game.add(BombComponent(motion: motion));
    } else {
      final letter =
          GlyphAtlas.letters[_random.nextInt(GlyphAtlas.letters.length)];
      game.add(LetterComponent(
        letter: letter,
        image: game.atlas.imageFor(letter),
        motion: motion,
      ));
    }
  }
}
```

- [ ] **Step 4: Wire the Spawner into `startGame` in `alaif_game.dart`**

Add the import:

```dart
import 'spawner.dart';
```

In `startGame()`, extend the cleanup filter and add a fresh spawner. Replace the existing `children.where(...)` block and the lines after it with:

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
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
```

(A fresh spawner per game resets the difficulty ramp.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/game/`
Expected: spawner tests PASS, plus all Task 11 tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/game/spawner.dart lib/game/alaif_game.dart test/game/spawner_test.dart
git commit -m "feat: add Spawner with difficulty ramp"
```

---

### Task 13: BladeTrail (M1)

**Files:**
- Create: `app/lib/game/blade_trail.dart`
- Modify: `app/lib/game/alaif_game.dart` (install BladeTrail + Hud once)
- Test: `app/test/game/blade_trail_test.dart`

Drag-gesture simulation in flame_test is brittle; the slice math is already covered by `hit_test_test.dart` and `alaif_game_test.dart`. Here we test installation and the buffer wiring directly.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/blade_trail.dart';
import 'package:alaif/game/hud.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('startGame installs blade trail and hud once',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    game.startGame();
    game.update(0);
    expect(game.children.whereType<BladeTrail>().length, 1);
    expect(game.children.whereType<Hud>().length, 1);
  });

  testWithGame<AlaifGame>('blade trail covers the full screen', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.size, game.size);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/blade_trail_test.dart`
Expected: FAIL — `blade_trail.dart` not found.

- [ ] **Step 3: Write `blade_trail.dart`**

API note: this targets current Flame 1.x event classes — `DragStartEvent.localPosition` and `DragUpdateEvent.localEndPosition`. If the resolved Flame version reports no such getter, check the flame changelog for the renamed accessor on these event types and use the local-coordinates variant; do not silently switch to global coordinates.

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/trail_buffer.dart';
import 'alaif_game.dart';

/// Full-screen drag catcher: records the swipe, draws the trail,
/// and reports each new segment to the game for slicing.
class BladeTrail extends PositionComponent
    with DragCallbacks, HasGameReference<AlaifGame> {
  final TrailBuffer buffer = TrailBuffer();
  double _time = 0;

  @override
  Future<void> onLoad() async {
    position = Vector2.zero();
    size = game.size.clone();
    priority = 100;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize.clone();
  }

  @override
  void update(double dt) {
    _time += dt;
    buffer.prune(_time);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    buffer.clear();
    buffer.add(event.localPosition, _time);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final previous =
        buffer.points.isEmpty ? null : buffer.points.last.position;
    buffer.add(event.localEndPosition, _time);
    if (previous != null) {
      game.trySlice(previous, event.localEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.endSwipe();
    buffer.clear();
  }

  @override
  void render(ui.Canvas canvas) {
    final pts = buffer.points;
    if (pts.length < 2) return;
    final path = ui.Path()
      ..moveTo(pts.first.position.x, pts.first.position.y);
    for (final p in pts.skip(1)) {
      path.lineTo(p.position.x, p.position.y);
    }
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round,
    );
  }
}
```

- [ ] **Step 4: Install BladeTrail and Hud in `alaif_game.dart`**

Add imports:

```dart
import 'blade_trail.dart';
import 'hud.dart';
```

In `startGame()`, immediately after `add(Spawner());`, add:

```dart
    if (children.whereType<BladeTrail>().isEmpty) {
      add(BladeTrail());
      add(Hud());
    }
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/game/`
Expected: all game tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/game/blade_trail.dart lib/game/alaif_game.dart test/game/blade_trail_test.dart
git commit -m "feat: add BladeTrail swipe input and trail rendering"
```

---

### Task 14: Overlays + app shell (M2)

**Files:**
- Create: `app/lib/ui/menu_overlay.dart`
- Create: `app/lib/ui/game_over_overlay.dart`
- Create: `app/lib/ui/pause_overlay.dart`
- Modify: `app/lib/main.dart` (replace placeholder entirely)
- Test: `app/test/ui/overlays_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/game_over_overlay.dart';
import 'package:alaif/ui/menu_overlay.dart';
import 'package:alaif/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'highScore': 70}));

  testWidgets('menu shows title, best score, and Play', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MenuOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();
    expect(find.text('Alaif'), findsOneWidget);
    expect(find.text('Best: 70'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('game over shows final score and Play Again', (tester) async {
    final game = AlaifGame();
    await tester
        .pumpWidget(MaterialApp(home: GameOverOverlay(game: game)));
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
  });

  testWidgets('pause overlay shows Resume', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: PauseOverlay(game: AlaifGame())));
    expect(find.text('Resume'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/overlays_test.dart`
Expected: FAIL — overlay files not found.

- [ ] **Step 3: Write `menu_overlay.dart`**

```dart
import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Alaif',
              style: TextStyle(fontSize: 64, color: Colors.white)),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: game.highScores.read(),
            builder: (context, snapshot) => Text(
              'Best: ${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: game.startGame,
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Write `game_over_overlay.dart`**

```dart
import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Game Over',
              style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Score: ${game.scoreState.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white)),
          FutureBuilder<int>(
            future: game.highScores.read(),
            builder: (context, snapshot) => Text(
              'Best: ${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: game.startGame,
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Write `pause_overlay.dart`**

```dart
import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Paused',
              style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: game.resumeFromPause,
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Replace `lib/main.dart`**

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/alaif_game.dart';
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AlaifApp());
}

class AlaifApp extends StatelessWidget {
  const AlaifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: GameWidget<AlaifGame>.controlled(
            gameFactory: AlaifGame.new,
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test`
Expected: entire suite PASSES.

- [ ] **Step 8: Commit**

```bash
git add lib/ui/ lib/main.dart test/ui/overlays_test.dart
git commit -m "feat: add overlays and app shell"
```

---

### Task 15: Full verification + wiki bookkeeping

**Files:**
- Modify: `wiki/log.md` (append entry)

- [ ] **Step 1: Run the full suite and analyzer**

Run: `flutter analyze && flutter test`
Expected: zero analyzer issues, all tests PASS.

- [ ] **Step 2: Manual smoke test on a device or simulator**

Run: `flutter run` (pick an iOS simulator or Android emulator/device).

Checklist — verify each by playing:
- Menu shows; Play starts the game.
- Letters arc up from the bottom and tumble; swiping draws a white trail.
- Slicing a letter splits it into two falling halves and increments the score.
- Slicing 3+ letters in one swipe adds a visible combo bonus at swipe end.
- Bombs appear occasionally; slicing one drops a life.
- Letting 3 letters fall ends the game with the Game Over overlay.
- Play Again restarts cleanly (score 0, lives 3, difficulty reset).
- Backgrounding the app mid-game shows the Paused overlay on return; Resume works.
- High score persists across an app restart.

If anything fails, fix it (using superpowers:systematic-debugging) before proceeding.

- [ ] **Step 3: Append to the wiki log**

Add to `wiki/log.md`:

```markdown
## [<today's date>] decision | M0–M2 core game implemented
Core game complete per plans/2026-06-09-alaif-core-game-m0-m2: playable Classic mode with slicing, combos, bombs, lives, game over, persisted high score. Next: M3 (juice) plan.
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: complete M0-M2 core game"
```

---

## Out of Scope (future plans)

- **M3 — Juice:** particles on slice, trail glow/fade, audio (`flame_audio`), haptics, combo popup text, bundled calligraphic Arabic font.
- **M4 — Polish:** settings screen (sound/haptics toggles persisted), high-scores screen, menu visual design, app icon/splash.
- **M5 — Store prep:** icons, screenshots, paid listings, signing, release builds.
