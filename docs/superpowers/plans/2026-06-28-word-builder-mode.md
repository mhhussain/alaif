# Word Builder Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Word Builder game mode where a 3–5 letter Arabic word is shown at the top and the player must slice falling letters in order to build it.

**Architecture:** A `GameMode` enum threads through `AlaifGame.startGame()`, branching spawning (new `WordBuilderSpawner` replaces `Spawner`+`SurgeScheduler`) and slice handling. `WordState` tracks the current word and target index. `HighScoreStore` gains a mode key for separate leaderboards. The main menu gains a second button.

**Tech Stack:** Flutter + Flame 1.35. Pure-Dart logic tested with `flutter_test`; game-component tests use `flame_test/testWithGame`.

## Global Constraints

- All tests run via `cd app && flutter test` — every task must leave the suite green.
- No new pub dependencies.
- Arabic letters in word lists must only use the 28 isolated-form letters already in `GlyphAtlas.letters`: `ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي` — no `ة ى ء أ إ آ`.
- Follow existing code style: no comments unless non-obvious, no trailing summaries, small focused files.
- Test commands: `cd app && flutter test test/path/to_test.dart -v` for a single file; `cd app && flutter test` for all.

---

## File Map

**New files:**
- `app/lib/core/game_mode.dart` — `GameMode` enum
- `app/lib/core/word_list.dart` — hardcoded word buckets (3/4/5 letters)
- `app/lib/core/word_state.dart` — current word + target-index tracking
- `app/lib/game/word_builder_spawner.dart` — cluster-based spawner for WB mode
- `app/test/core/word_state_test.dart`
- `app/test/game/word_builder_spawner_test.dart`

**Modified files:**
- `app/lib/core/score_state.dart` — add `addPoints(int)`
- `app/lib/services/high_score_store.dart` — mode-keyed read/submit
- `app/lib/game/letter_component.dart` — add optional `wordIndex` field
- `app/lib/game/alaif_game.dart` — mode field, WB slice/miss logic, word lifecycle
- `app/lib/game/hud.dart` — word progress display in WB mode
- `app/lib/ui/menu_overlay.dart` — second "Word Builder" button
- `app/test/core/score_state_test.dart` — addPoints test
- `app/test/services/high_score_store_test.dart` — mode-keyed tests
- `app/test/game/alaif_game_test.dart` — WB mode tests
- `app/test/game/hud_test.dart` — WB HUD render test

---

## Task 1: GameMode enum, WordList, WordState

**Files:**
- Create: `app/lib/core/game_mode.dart`
- Create: `app/lib/core/word_list.dart`
- Create: `app/lib/core/word_state.dart`
- Create: `app/test/core/word_state_test.dart`

**Interfaces:**
- Produces:
  - `enum GameMode { classic, wordBuilder }` (imported by all other tasks)
  - `const List<String> threeLetterWords`, `fourLetterWords`, `fiveLetterWords` (used in Task 5)
  - `class WordState` with: `String get currentWord`, `int get targetIndex`, `String get currentTarget`, `bool get wordComplete`, `int get pointsForCurrentWord`, `void setWord(String)`, `void advanceTarget()`, `void reset()`

- [ ] **Step 1: Write failing tests**

```dart
// app/test/core/word_state_test.dart
import 'package:alaif/core/word_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial state is empty', () {
    final ws = WordState();
    expect(ws.currentWord, '');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isTrue);
  });

  test('setWord sets word and resets targetIndex', () {
    final ws = WordState()..setWord('بيت');
    expect(ws.currentWord, 'بيت');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isFalse);
    expect(ws.currentTarget, 'ب');
  });

  test('advanceTarget moves the target forward', () {
    final ws = WordState()..setWord('بيت');
    ws.advanceTarget();
    expect(ws.targetIndex, 1);
    expect(ws.currentTarget, 'ي');
  });

  test('wordComplete is true after all letters are advanced past', () {
    final ws = WordState()..setWord('بيت');
    ws.advanceTarget();
    ws.advanceTarget();
    ws.advanceTarget();
    expect(ws.wordComplete, isTrue);
  });

  test('pointsForCurrentWord: 100 for 3, 150 for 4, 200 for 5', () {
    expect((WordState()..setWord('بيت')).pointsForCurrentWord, 100);
    expect((WordState()..setWord('كتاب')).pointsForCurrentWord, 150);
    expect((WordState()..setWord('سلطان')).pointsForCurrentWord, 200);
  });

  test('reset clears word and index', () {
    final ws = WordState()..setWord('بيت')..advanceTarget();
    ws.reset();
    expect(ws.currentWord, '');
    expect(ws.targetIndex, 0);
    expect(ws.wordComplete, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

```
cd app && flutter test test/core/word_state_test.dart -v
```
Expected: FAIL — `word_state.dart` not found.

- [ ] **Step 3: Create `game_mode.dart`**

```dart
// app/lib/core/game_mode.dart
enum GameMode { classic, wordBuilder }
```

- [ ] **Step 4: Create `word_list.dart`**

```dart
// app/lib/core/word_list.dart
const List<String> threeLetterWords = [
  'بحر', 'قمر', 'شمس', 'نهر', 'بيت', 'يوم', 'ليل', 'نور',
  'ذهب', 'قلب', 'حجر', 'عقل', 'طير', 'دين', 'خبز', 'صبر',
  'فكر', 'غرب', 'حرب', 'نمر',
];

const List<String> fourLetterWords = [
  'كتاب', 'سلام', 'طريق', 'قديم', 'كبير', 'رحيم', 'حكيم', 'صديق',
  'شريف', 'طبيب', 'نهار', 'سحاب', 'بريد', 'حديد', 'نسيم', 'بيوت',
  'بديع', 'جليل', 'ذهاب', 'سيوف',
];

const List<String> fiveLetterWords = [
  'سلطان', 'ميدان', 'بستان', 'ديوان', 'طوفان', 'فستان', 'منهاج', 'دستور',
  'جمهور', 'منشور', 'نيسان', 'بركان', 'ميزان', 'حيوان', 'درويش', 'صنوبر',
  'سنابل', 'قنطار', 'شيطان', 'غيلان',
];
```

- [ ] **Step 5: Create `word_state.dart`**

```dart
// app/lib/core/word_state.dart
class WordState {
  static const pointsPerThreeLetter = 100;
  static const pointsPerFourLetter = 150;
  static const pointsPerFiveLetter = 200;

  String _currentWord = '';
  int _targetIndex = 0;

  String get currentWord => _currentWord;
  int get targetIndex => _targetIndex;
  bool get wordComplete => _targetIndex >= _currentWord.length;

  String get currentTarget {
    if (wordComplete) throw StateError('No current target: word is complete or empty');
    return _currentWord[_targetIndex];
  }

  int get pointsForCurrentWord => switch (_currentWord.length) {
    3 => pointsPerThreeLetter,
    4 => pointsPerFourLetter,
    _ => pointsPerFiveLetter,
  };

  void setWord(String word) {
    _currentWord = word;
    _targetIndex = 0;
  }

  void advanceTarget() {
    _targetIndex++;
  }

  void reset() {
    _currentWord = '';
    _targetIndex = 0;
  }
}
```

- [ ] **Step 6: Run tests — expect PASS**

```
cd app && flutter test test/core/word_state_test.dart -v
```

- [ ] **Step 7: Commit**

```bash
git add app/lib/core/game_mode.dart app/lib/core/word_list.dart app/lib/core/word_state.dart app/test/core/word_state_test.dart
git commit -m "feat: add GameMode enum, word list, and WordState"
```

---

## Task 2: ScoreState.addPoints + HighScoreStore mode keys

**Files:**
- Modify: `app/lib/core/score_state.dart`
- Modify: `app/lib/services/high_score_store.dart`
- Modify: `app/test/core/score_state_test.dart`
- Modify: `app/test/services/high_score_store_test.dart`

**Interfaces:**
- Consumes: `GameMode` from `app/lib/core/game_mode.dart`
- Produces:
  - `ScoreState.addPoints(int amount)` — adds directly to score, no combo logic
  - `HighScoreStore.read({GameMode mode = GameMode.classic})` — reads score for mode
  - `HighScoreStore.submit(int score, {GameMode mode = GameMode.classic})` — submits for mode

- [ ] **Step 1: Write failing tests — append to existing test files**

Add to `app/test/core/score_state_test.dart` (inside `main()`):

```dart
test('addPoints increases score directly', () {
  final s = ScoreState();
  s.addPoints(150);
  expect(s.score, 150);
  s.addPoints(50);
  expect(s.score, 200);
});
```

Add to `app/test/services/high_score_store_test.dart` (inside `main()`):

```dart
import 'package:alaif/core/game_mode.dart';
// (add to existing imports at top)

test('classic and wordBuilder have separate high scores', () async {
  final store = HighScoreStore();
  await store.submit(500, mode: GameMode.classic);
  await store.submit(300, mode: GameMode.wordBuilder);
  expect(await store.read(mode: GameMode.classic), 500);
  expect(await store.read(mode: GameMode.wordBuilder), 300);
});

test('default mode is classic — existing key is unchanged', () async {
  final store = HighScoreStore();
  await store.submit(200);
  expect(await store.read(), 200);
});
```

- [ ] **Step 2: Run to verify they fail**

```
cd app && flutter test test/core/score_state_test.dart test/services/high_score_store_test.dart -v
```
Expected: FAIL — `addPoints` not defined; `submit`/`read` don't accept `mode`.

- [ ] **Step 3: Add `addPoints` to `ScoreState`**

In `app/lib/core/score_state.dart`, add after `endSwipe()`:

```dart
  void addPoints(int amount) {
    _score += amount;
  }
```

- [ ] **Step 4: Update `HighScoreStore`**

Replace `app/lib/services/high_score_store.dart` entirely:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_mode.dart';

class HighScoreStore {
  static String _key(GameMode mode) =>
      mode == GameMode.classic ? 'highScore' : 'highScore.wordBuilder';

  Future<int> read({GameMode mode = GameMode.classic}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key(mode)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> submit(int score, {GameMode mode = GameMode.classic}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(mode);
      if (score > (prefs.getInt(key) ?? 0)) {
        await prefs.setInt(key, score);
      }
    } catch (_) {
      // A lost high score must never crash gameplay.
    }
  }
}
```

- [ ] **Step 5: Run tests — expect PASS**

```
cd app && flutter test test/core/score_state_test.dart test/services/high_score_store_test.dart -v
```

- [ ] **Step 6: Run full suite to check nothing broke**

```
cd app && flutter test
```

- [ ] **Step 7: Commit**

```bash
git add app/lib/core/score_state.dart app/lib/services/high_score_store.dart app/test/core/score_state_test.dart app/test/services/high_score_store_test.dart
git commit -m "feat: add ScoreState.addPoints and mode-keyed HighScoreStore"
```

---

## Task 3: LetterComponent wordIndex field

**Files:**
- Modify: `app/lib/game/letter_component.dart`

**Interfaces:**
- Produces: `LetterComponent` has `final int? wordIndex` — optional, defaults `null`, set by `WordBuilderSpawner`. Used by `AlaifGame` in Tasks 4 and 5.

No new tests needed — existing tests construct `LetterComponent` without `wordIndex` and must still pass.

- [ ] **Step 1: Add `wordIndex` to `LetterComponent`**

In `app/lib/game/letter_component.dart`, add `wordIndex` to the constructor and as a field:

```dart
class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
    double targetSize = AlaifGlyph.spawnSizeMax,
    math.Random? random,
    this.wordIndex,          // <-- add this line
  }) : _image = image {
```

And add the field declaration alongside `letter` and `motion`:

```dart
  final String letter;
  final ArcMotion motion;
  final int? wordIndex;     // <-- add this line
  final ui.Image _image;
```

- [ ] **Step 2: Run full suite to confirm no breakage**

```
cd app && flutter test
```
Expected: all PASS.

- [ ] **Step 3: Commit**

```bash
git add app/lib/game/letter_component.dart
git commit -m "feat: add optional wordIndex to LetterComponent"
```

---

## Task 4: WordBuilderSpawner

**Files:**
- Create: `app/lib/game/word_builder_spawner.dart`
- Create: `app/test/game/word_builder_spawner_test.dart`

**Interfaces:**
- Consumes:
  - `AlaifGame.wordState` (type `WordState`) — reads `currentWord`
  - `AlaifGame.isPlaying` — gates update
  - `AlaifGame.isWordPaused` — gates spawning (paused between words); added in Task 5
  - `LetterComponent(letter, image, motion, wordIndex: i)` — from Tasks 3 and existing code
  - `GlyphAtlas.imageFor(letter)`, `GlyphAtlas.letters`
  - `ArcMotion`, `AlaifGlyph`, `AlaifCard`
- Produces: `WordBuilderSpawner({Random? random})` — component added to game in WB mode

**Note on `game.isWordPaused`:** Task 5 adds `bool get isWordPaused` to `AlaifGame`. For tests here, use a subclass stub or just verify spawner doesn't crash when `isPlaying` is false.

- [ ] **Step 1: Write failing tests**

```dart
// app/test/game/word_builder_spawner_test.dart
import 'dart:math';
import 'package:alaif/core/word_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/word_builder_spawner.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('spawner emits letters from the current word over time',
      AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);

    // Advance past the first cluster interval
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }

    final letters = game.children.whereType<LetterComponent>().toList();
    expect(letters, isNotEmpty);
    final wordLetters = game.wordState.currentWord.split('');
    for (final l in letters) {
      expect(wordLetters, contains(l.letter));
    }
  });

  testWithGame<AlaifGame>('spawned letters have a non-null wordIndex',
      AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }
    for (final l in game.children.whereType<LetterComponent>()) {
      expect(l.wordIndex, isNotNull);
    }
  });

  testWithGame<AlaifGame>(
      'spawner does not emit when word is empty', AlaifGame.new, (game) async {
    game.startGame(mode: GameMode.wordBuilder);
    game.update(0);
    game.wordState.reset(); // clear the word
    for (var i = 0; i < 25; i++) {
      game.update(0.1);
    }
    expect(game.children.whereType<LetterComponent>(), isEmpty);
  });
}
```

- [ ] **Step 2: Run to verify they fail**

```
cd app && flutter test test/game/word_builder_spawner_test.dart -v
```
Expected: FAIL — `word_builder_spawner.dart` not found, `startGame` doesn't accept `mode` yet.

- [ ] **Step 3: Create `word_builder_spawner.dart`**

```dart
// app/lib/game/word_builder_spawner.dart
import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';
import 'letter_component.dart';

class WordBuilderSpawner extends Component with HasGameReference<AlaifGame> {
  WordBuilderSpawner({Random? random}) : _random = random ?? Random();

  static const clusterInterval = 2.0;
  static const _clusterSizes = [1, 3, 5];

  final Random _random;
  double _untilNext = 0.5;

  @override
  void update(double dt) {
    if (!game.isPlaying || game.isWordPaused) return;
    _untilNext -= dt;
    if (_untilNext <= 0) {
      _spawnCluster();
      _untilNext = clusterInterval;
    }
  }

  void _spawnCluster() {
    final word = game.wordState.currentWord;
    if (word.isEmpty) return;
    final size = _clusterSizes[_random.nextInt(_clusterSizes.length)];
    for (var i = 0; i < size; i++) {
      final wordIndex = _random.nextInt(word.length);
      _spawnLetter(word[wordIndex], wordIndex);
    }
  }

  void _spawnLetter(String letter, int wordIndex) {
    final screen = game.size;
    final x = screen.x * (0.15 + 0.7 * _random.nextDouble());
    final start = Vector2(x, screen.y + 60);
    final vx = (screen.x / 2 - x) * (0.3 + 0.4 * _random.nextDouble());
    final vy = -screen.y * (0.877 + 0.145 * _random.nextDouble());
    final motion = ArcMotion(
      start: start,
      velocity: Vector2(vx, vy),
      gravity: screen.y * 0.55,
    );
    final targetSize = AlaifGlyph.spawnSizeMin +
        (AlaifGlyph.spawnSizeMax - AlaifGlyph.spawnSizeMin) *
            _random.nextDouble();
    game.add(LetterComponent(
      letter: letter,
      image: game.atlas.imageFor(letter),
      motion: motion,
      targetSize: targetSize,
      random: _random,
      wordIndex: wordIndex,
    ));
  }
}
```

These tests depend on Task 5 (`startGame(mode:)` and `game.isWordPaused`). Implement Task 5 before running them to green — see Step 5 below.

- [ ] **Step 4: Commit stub**

```bash
git add app/lib/game/word_builder_spawner.dart app/test/game/word_builder_spawner_test.dart
git commit -m "feat: add WordBuilderSpawner"
```

---

## Task 5: AlaifGame word builder wiring

**Files:**
- Modify: `app/lib/game/alaif_game.dart`
- Modify: `app/test/game/alaif_game_test.dart`

**Interfaces:**
- Consumes (new):
  - `GameMode` from `game_mode.dart`
  - `WordState` from `word_state.dart`
  - `WordBuilderSpawner` from `word_builder_spawner.dart`
  - `threeLetterWords`, `fourLetterWords`, `fiveLetterWords` from `word_list.dart`
  - `HighScoreStore.submit(score, mode: _mode)` — updated signature
- Produces (new public API):
  - `void startGame({GameMode mode = GameMode.classic})`
  - `bool get isWordPaused` — true during 0.5s inter-word pause
  - `GameMode get mode` — current game mode
  - `final WordState wordState` — on the game instance

**Key behaviors:**

*startGame(mode):*
- Stores `_mode = mode`
- Resets `wordState`
- If `wordBuilder`: adds `WordBuilderSpawner()` instead of `Spawner` + `SurgeScheduler`; calls `_startNextWord()`
- If `classic`: adds `Spawner()` + `SurgeScheduler()` (existing behavior)
- `quitToMenu` and the cleanup block must also remove `WordBuilderSpawner`

*trySlice in WB mode (wordBuilder branch):*
- If `letter.wordIndex == wordState.targetIndex`: correct — remove letter, ink burst, haptics.onSlice(), audio.playSlice(), `wordState.advanceTarget()`, check `wordState.wordComplete → _completeWord()`
- If `letter.wordIndex != wordState.targetIndex`: wrong order — remove letter, ink burst, `rules.onLetterMissed()`, `haptics.onBomb()`, `audio.playBomb()`, `_checkGameOver()`

*update in WB mode:*
- Missed letter check: only letters where `letter.wordIndex == wordState.targetIndex` cost a life when they fall off
- Word pause countdown: `_wordPauseRemaining -= dt`; when it reaches 0, call `_startNextWord()`
- Non-target letters that fall off: remove silently (no life lost)

*_completeWord():*
- Add `wordState.pointsForCurrentWord` via `scoreState.addPoints(...)`
- Clear all `LetterComponent` from game
- Play combo audio (`audio.playCombo()`) as celebration sound
- Set `_wordPauseRemaining = 0.5`

*_startNextWord():*
- Pick bucket by score: `< 300 → threeLetterWords`, `< 900 → fourLetterWords`, else `fiveLetterWords`
- Pick random word from bucket: `bucket[_random.nextInt(bucket.length)]`
- Call `wordState.setWord(word)`

*_checkGameOver in WB mode:*
- Same as classic — call `highScores.submit(scoreState.score, mode: _mode)`

- [ ] **Step 1: Write failing tests — add WB-specific tests to alaif_game_test.dart**

Add these inside `main()` in `app/test/game/alaif_game_test.dart`:

```dart
// Add imports at top:
// import 'package:alaif/core/game_mode.dart';
// import 'package:alaif/game/word_builder_spawner.dart';

testWithGame<AlaifGame>(
    'startGame(wordBuilder) adds WordBuilderSpawner, not Spawner or SurgeScheduler',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);
  expect(game.children.whereType<WordBuilderSpawner>().length, 1);
  expect(game.children.whereType<Spawner>(), isEmpty);
  expect(game.children.whereType<SurgeScheduler>(), isEmpty);
});

testWithGame<AlaifGame>(
    'startGame(wordBuilder) sets a current word from the three-letter bucket',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);
  expect(game.wordState.currentWord.length, 3); // score starts at 0 → 3-letter bucket
  expect(game.wordState.targetIndex, 0);
});

testWithGame<AlaifGame>(
    'slicing the current target letter in WB mode advances the target',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);

  final word = game.wordState.currentWord;
  game.add(LetterComponent(
    letter: word[0],
    image: game.atlas.imageFor(word[0]),
    motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    wordIndex: 0,
  ));
  game.update(0);
  game.trySlice(Vector2(0, 300), Vector2(200, 300));
  game.update(0);

  expect(game.wordState.targetIndex, 1);
  expect(game.rules.lives, 3); // no life lost
});

testWithGame<AlaifGame>(
    'slicing an out-of-order letter in WB mode costs a life',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);

  final word = game.wordState.currentWord;
  // Add letter at index 1 (not the target, which is index 0)
  game.add(LetterComponent(
    letter: word[1],
    image: game.atlas.imageFor(word[1]),
    motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    wordIndex: 1,
  ));
  game.update(0);
  game.trySlice(Vector2(0, 300), Vector2(200, 300));
  game.update(0);

  expect(game.rules.lives, 2);
  expect(game.wordState.targetIndex, 0); // target did not advance
});

testWithGame<AlaifGame>(
    'current target falling off screen in WB mode costs a life',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);

  final word = game.wordState.currentWord;
  final letter = LetterComponent(
    letter: word[0],
    image: game.atlas.imageFor(word[0]),
    motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    wordIndex: 0,
  )..entered = true;
  game.add(letter);
  game.update(0);

  letter.position.y = game.size.y + 500;
  game.update(0);

  expect(game.rules.lives, 2);
});

testWithGame<AlaifGame>(
    'non-target letter falling off screen in WB mode does NOT cost a life',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);

  final word = game.wordState.currentWord;
  final letter = LetterComponent(
    letter: word[1],
    image: game.atlas.imageFor(word[1]),
    motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    wordIndex: 1,
  )..entered = true;
  game.add(letter);
  game.update(0);

  letter.position.y = game.size.y + 500;
  game.update(0);

  expect(game.rules.lives, 3);
  expect(game.children.whereType<LetterComponent>(), isEmpty);
});

testWithGame<AlaifGame>(
    'completing a word clears letters, adds points, and pauses briefly',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);

  // Force a known 3-letter word
  game.wordState.setWord('بيت');

  void addAndSlice(String letter, int index) {
    game.add(LetterComponent(
      letter: letter,
      image: game.atlas.imageFor(letter),
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
      wordIndex: index,
    ));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);
  }

  addAndSlice('ب', 0);
  addAndSlice('ي', 1);
  addAndSlice('ت', 2);

  // Word complete: score = 100, letters cleared, word pause active
  expect(game.scoreState.score, 100);
  expect(game.children.whereType<LetterComponent>(), isEmpty);
  expect(game.isWordPaused, isTrue);
});

testWithGame<AlaifGame>(
    'after the inter-word pause a new word begins', AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);
  game.wordState.setWord('بيت');

  void addAndSlice(String letter, int index) {
    game.add(LetterComponent(
      letter: letter,
      image: game.atlas.imageFor(letter),
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
      wordIndex: index,
    ));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);
  }

  addAndSlice('ب', 0);
  addAndSlice('ي', 1);
  addAndSlice('ت', 2);

  expect(game.isWordPaused, isTrue);
  game.update(0.6); // advance past the 0.5s pause
  expect(game.isWordPaused, isFalse);
  expect(game.wordState.currentWord, isNotEmpty);
  expect(game.wordState.targetIndex, 0);
});

testWithGame<AlaifGame>(
    'quitToMenu removes WordBuilderSpawner', AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);
  expect(game.children.whereType<WordBuilderSpawner>().length, 1);
  game.quitToMenu();
  game.update(0);
  expect(game.children.whereType<WordBuilderSpawner>(), isEmpty);
});
```

- [ ] **Step 2: Run to verify they fail**

```
cd app && flutter test test/game/alaif_game_test.dart -v
```
Expected: FAIL on new tests, existing tests PASS.

- [ ] **Step 3: Update `alaif_game.dart` imports and fields**

Add to imports:
```dart
import '../core/game_mode.dart';
import '../core/word_list.dart';
import '../core/word_state.dart';
import 'word_builder_spawner.dart';
```

Add fields after `final Random _random;`:
```dart
  GameMode _mode = GameMode.classic;
  GameMode get mode => _mode;
  final WordState wordState = WordState();
  double _wordPauseRemaining = 0;
  bool get isWordPaused => _wordPauseRemaining > 0;
```

- [ ] **Step 4: Update `startGame` signature and body**

Replace `void startGame()` with:

```dart
  void startGame({GameMode mode = GameMode.classic}) {
    _mode = mode;
    scoreState.reset();
    rules.reset();
    wordState.reset();
    _wordPauseRemaining = 0;
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner ||
            c is SurgeScheduler ||
            c is WordBuilderSpawner)
        .toList()
        .forEach((c) => c.removeFromParent());
    if (_mode == GameMode.wordBuilder) {
      add(WordBuilderSpawner());
      _startNextWord();
    } else {
      add(Spawner());
      add(SurgeScheduler());
    }
    if (!_hudInstalled) {
      _hudInstalled = true;
      add(BladeTrail());
      add(Hud());
    }
    if (paused) resumeEngine();
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
    overlays.remove('paused');
    overlays.add('controls');
  }
```

- [ ] **Step 5: Add `_startNextWord` and `_completeWord` private methods**

Add after `startGame`:

```dart
  void _startNextWord() {
    final bucket = scoreState.score < 300
        ? threeLetterWords
        : scoreState.score < 900
            ? fourLetterWords
            : fiveLetterWords;
    wordState.setWord(bucket[_random.nextInt(bucket.length)]);
  }

  void _completeWord() {
    scoreState.addPoints(wordState.pointsForCurrentWord);
    children.whereType<LetterComponent>().toList().forEach((c) => c.removeFromParent());
    audio.playCombo();
    _wordPauseRemaining = 0.5;
  }
```

- [ ] **Step 6: Update `trySlice` to branch on mode**

Replace the letter-slice loop in `trySlice` with a mode-aware version:

```dart
  void trySlice(Vector2 from, Vector2 to) {
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        if (_mode == GameMode.wordBuilder) {
          _sliceLetterWordBuilder(letter);
        } else {
          _sliceLetter(letter, from, to);
        }
      }
    }
    if (_mode == GameMode.classic) {
      for (final bomb in children.whereType<BombComponent>().toList()) {
        if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
          add(InkBurstComponent(particles: spawnBombBurst(bomb.position, _random)));
          bomb.removeFromParent();
          rules.onBombSliced();
          haptics.onBomb();
          audio.playBomb();
          _checkGameOver();
        }
      }
    }
  }
```

Add the new WB slice method after `_sliceLetter`:

```dart
  void _sliceLetterWordBuilder(LetterComponent letter) {
    letter.sliced = true;
    letter.removeFromParent();
    add(InkBurstComponent(particles: spawnCutBurst(letter.position, _random)));

    if (letter.wordIndex == wordState.targetIndex) {
      haptics.onSlice();
      audio.playSlice();
      _hitStopRemainingMs = AlaifMotion.hitStopMs.toDouble();
      wordState.advanceTarget();
      if (wordState.wordComplete) _completeWord();
    } else {
      haptics.onBomb();
      audio.playBomb();
      rules.onLetterMissed();
      _checkGameOver();
    }
  }
```

- [ ] **Step 7: Update `update` to handle WB word-pause and missed-letter logic**

In `update`, replace the letter-missed check block with a mode-aware one:

```dart
    if (_playing) {
      if (_mode == GameMode.wordBuilder && _wordPauseRemaining > 0) {
        _wordPauseRemaining -= dt;
        if (_wordPauseRemaining <= 0) {
          _startNextWord();
        }
      }

      for (final letter in children.whereType<LetterComponent>().toList()) {
        if (!letter.entered && letter.position.y < size.y) letter.entered = true;
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          if (_mode == GameMode.classic ||
              letter.wordIndex == wordState.targetIndex) {
            rules.onLetterMissed();
            haptics.onMiss();
            audio.playMiss();
            _checkGameOver();
          }
        }
      }
      // Bomb miss check (classic only — no bombs in WB mode)
      if (_mode == GameMode.classic) {
        for (final bomb in children.whereType<BombComponent>().toList()) {
          if (!bomb.entered && bomb.position.y < size.y) bomb.entered = true;
          if (bomb.entered && bomb.position.y > size.y + 120) {
            bomb.removeFromParent();
          }
        }
      }
    }
```

- [ ] **Step 8: Update `quitToMenu` cleanup and `_checkGameOver` to pass mode**

In `quitToMenu`, add `WordBuilderSpawner` to the cleanup list:

```dart
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner ||
            c is SurgeScheduler ||
            c is WordBuilderSpawner)
        .toList()
        .forEach((c) => c.removeFromParent());
```

In `_checkGameOver`, update the `highScores.submit` call:

```dart
    unawaited(highScores.submit(scoreState.score, mode: _mode));
```

- [ ] **Step 9: Run all tests — expect PASS**

```
cd app && flutter test
```

- [ ] **Step 10: Commit**

```bash
git add app/lib/game/alaif_game.dart app/test/game/alaif_game_test.dart
git commit -m "feat: wire WordBuilder mode into AlaifGame"
```

Now run the word builder spawner tests that depend on this task:

```
cd app && flutter test test/game/word_builder_spawner_test.dart -v
```
Expected: PASS.

---

## Task 6: Hud word progress display

**Files:**
- Modify: `app/lib/game/hud.dart`
- Modify: `app/test/game/hud_test.dart`

**Interfaces:**
- Consumes: `game.mode` (GameMode), `game.wordState` (WordState)
- Produces: `Hud.render` shows word progress bar when `game.mode == GameMode.wordBuilder`

**Design:** Letters render at top-center of screen, in RTL visual order (index 0 is rightmost). Colors: sliced letters use `AlaifColors.hairline`, current target uses `AlaifColors.ink`, future letters use `AlaifColors.hairline` at 40% opacity. Font: Katibeh 24px. Y position: `livesRowCenterY + 24 + game.safePadding.top` (one row below score/lives). Spacing: 32px per letter.

- [ ] **Step 1: Write failing test — add to hud_test.dart**

```dart
// add import: import 'package:alaif/core/game_mode.dart';

testWithGame<AlaifGame>('hud render does not throw in word builder mode',
    AlaifGame.new, (game) async {
  game.startGame(mode: GameMode.wordBuilder);
  game.update(0);
  final hud = game.children.whereType<Hud>().single;
  final recorder = ui.PictureRecorder();
  // Should not throw even when a word is set and mid-progress
  hud.render(ui.Canvas(recorder));
  recorder.endRecording().dispose();
});
```

- [ ] **Step 2: Run to verify**

```
cd app && flutter test test/game/hud_test.dart -v
```
Expected: new test PASS (render doesn't throw is the minimal bar). If it already passes, proceed — the next step adds the actual visual.

- [ ] **Step 3: Add word display rendering to Hud**

Add to imports in `hud.dart`:
```dart
import 'package:flutter/painting.dart' show TextDirection, TextSpan, TextStyle;
import '../core/game_mode.dart';
```

Add a word-display paint factory after existing `_scorePaint`:
```dart
  static TextPaint _wordLetterPaint(ui.Color color) =>
      TextPaint(style: TextStyle(
        fontFamily: AlaifFonts.arabic,
        fontSize: 24,
        color: color,
      ));
```

Add `_renderWord` call at the end of `render`:
```dart
  @override
  void render(ui.Canvas canvas) {
    // ... existing score and lives rendering unchanged ...

    if (game.mode == GameMode.wordBuilder) {
      _renderWordProgress(canvas);
    }
  }

  void _renderWordProgress(ui.Canvas canvas) {
    final word = game.wordState.currentWord;
    if (word.isEmpty) return;
    final targetIndex = game.wordState.targetIndex;
    const spacing = 32.0;
    final totalWidth = (word.length - 1) * spacing;
    final centerX = size.x / 2;
    final y = livesRowCenterY + 30;

    for (var i = 0; i < word.length; i++) {
      // RTL visual order: index 0 is rightmost
      final x = centerX + totalWidth / 2 - i * spacing;
      final color = i < targetIndex
          ? AlaifColors.hairline
          : i == targetIndex
              ? AlaifColors.ink
              : AlaifColors.hairline.withAlpha(102); // ~40%
      _wordLetterPaint(color).render(canvas, word[i], Vector2(x, y));
    }
  }
```

- [ ] **Step 4: Run full hud tests**

```
cd app && flutter test test/game/hud_test.dart -v
```
Expected: all PASS.

- [ ] **Step 5: Run full suite**

```
cd app && flutter test
```

- [ ] **Step 6: Commit**

```bash
git add app/lib/game/hud.dart app/test/game/hud_test.dart
git commit -m "feat: add word progress display to Hud for WordBuilder mode"
```

---

## Task 7: MenuOverlay second button

**Files:**
- Modify: `app/lib/ui/menu_overlay.dart`

**Interfaces:**
- Consumes: `game.startGame(mode: GameMode.wordBuilder)`
- No new tests needed — `MenuOverlay` is a stateless widget with no observable state; visual correctness is verified manually.

- [ ] **Step 1: Add import and second button to MenuOverlay**

Add to imports in `menu_overlay.dart`:
```dart
import '../core/game_mode.dart';
```

Replace the `SizedBox` containing the single Play `ElevatedButton` with:

```dart
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: game.startGame,
                              child: const Text('Play'),
                            ),
                          ),
                          const SizedBox(height: AlaifSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () =>
                                  game.startGame(mode: GameMode.wordBuilder),
                              child: const Text('Word Builder'),
                            ),
                          ),
```

- [ ] **Step 2: Run full suite to confirm no breakage**

```
cd app && flutter test
```
Expected: all PASS.

- [ ] **Step 3: Commit**

```bash
git add app/lib/ui/menu_overlay.dart
git commit -m "feat: add Word Builder button to main menu"
```

---

## Self-Review Checklist

**Spec coverage:**
- [x] Only word letters spawn — `WordBuilderSpawner._spawnCluster` picks from `wordState.currentWord`
- [x] Order enforced — `_sliceLetterWordBuilder` checks `wordIndex == targetIndex`
- [x] Endless mode — no win condition; game ends only via lives exhaustion
- [x] Word length ramps with score — `_startNextWord` picks bucket by `scoreState.score`
- [x] Isolated forms — `GlyphAtlas.imageFor(letter)` used unchanged
- [x] Hardcoded word list — `word_list.dart`
- [x] Scoring per word — `_completeWord` calls `scoreState.addPoints(wordState.pointsForCurrentWord)`
- [x] Clusters of 1/3/5 with repeats — `_clusterSizes = [1, 3, 5]`, `wordIndex = random.nextInt(word.length)`
- [x] Fixed 2s interval — `clusterInterval = 2.0`
- [x] Only current target miss costs life — `update` gates on `letter.wordIndex == wordState.targetIndex`
- [x] Word display at top — `Hud._renderWordProgress`
- [x] Greyed sliced / full-ink target / dim future — color logic in `_renderWordProgress`
- [x] Two menu buttons — `MenuOverlay` updated
- [x] Separate high scores — `HighScoreStore._key(mode)` used in `_checkGameOver`
- [x] Clear letters on word complete + 0.5s pause — `_completeWord` clears and sets `_wordPauseRemaining = 0.5`
- [x] No bombs, no surge in WB mode — `trySlice` bombs block gated on `_mode == GameMode.classic`; `startGame(wordBuilder)` skips `SurgeScheduler`

**Type consistency:** `WordState.targetIndex` (int) used consistently as `letter.wordIndex` (int?) comparison via `==`. `GameMode` enum used throughout. `HighScoreStore.submit/read` named param `mode` used everywhere including `_checkGameOver`.
