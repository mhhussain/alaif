# Device Review 1 Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three device-review issues in the Alaif Flutter+Flame game — non-full-screen canvas, overlapping slice SFX from duplicate slices, and trivial-sliver letter cuts — while keeping all 110+ existing tests green.

**Architecture:** `AlaifGame` (Flame `FlameGame`) owns gameplay state and is hosted by `GameWidget` inside `MaterialApp`/`Scaffold` in `main.dart`; `LetterComponent`/`SlicedHalf`/`Hud`/`BladeTrail` are Flame components; `GlyphAtlas` pre-renders the 28 Arabic letters to `ui.Image` textures at load time; `AudioService` wraps `flame_audio`. All visuals use tokens from `lib/ui/design_tokens.dart`.

**Tech Stack:** Flutter 3.38, Flame, flame_audio, flutter_test, flame_test.

All commands below assume `cd /Users/iammoo/code/alaif/app` first (each task states this explicitly). Every task ends with the **full** test suite green (`flutter test`) before committing.

---

## Task 1: Slice dedup — `sliced` flag on `LetterComponent`

Prevents `trySlice` from re-slicing the same letter multiple times within one swipe (Flame defers `removeFromParent()` to the next tick, so a multi-segment drag can hit an already-sliced letter again before it's removed).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`

### Steps

- [ ] Write a failing test. Open `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` and add the following test inside `void main() { ... }`, immediately after the `'slicing a letter scores and spawns two halves'` test (after its closing `});`):

```dart
  testWithGame<AlaifGame>(
      'a letter already sliced this frame is not sliced again by a later segment',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0); // mount

    // Two swipe segments both cross the same letter before removal is
    // processed (Flame defers removeFromParent to the next update tick).
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process removal/additions

    expect(game.scoreState.score, ScoreState.pointsPerLetter);
    expect(game.children.whereType<SlicedHalf>().length, 2);
  });
```

- [ ] Run it and confirm it fails (currently scores double / spawns 4 halves):

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -40
```

  Expected: a failure on the new test, e.g. `Expected: <2>` but `Actual: <4>` for `SlicedHalf` count, and/or score `20` instead of `10`.

- [ ] Implement the minimal fix. In `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart`, add a `sliced` field. The class currently looks like:

```dart
  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;
```

  Change it to:

```dart
  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  /// Set the instant this letter is sliced, before `removeFromParent()` takes
  /// effect (which Flame defers to the next update tick). Prevents a single
  /// swipe's later drag-update segments from re-slicing the same letter.
  bool sliced = false;
```

  Then in `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`, update `trySlice` and `_sliceLetter`. The current `trySlice` letter loop is:

```dart
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
```

  Change it to:

```dart
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
```

  And the current `_sliceLetter` starts with:

```dart
  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
```

  Change it to:

```dart
  void _sliceLetter(LetterComponent letter) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -20
```

  Expected: all tests in this file pass (no failures listed).

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/letter_component.dart lib/game/alaif_game.dart test/game/alaif_game_test.dart && git commit -m "fix: dedupe letter slices within a single swipe via sliced flag"
```

---

## Task 2: Slice SFX cooldown in `AudioService`

Backstop for any remaining duplicate `playSlice()` calls (e.g. two different letters sliced in the same frame produce legitimate back-to-back `playSlice` calls — those are fine — but two calls within 60ms for what is effectively the same gesture-tick should not double up). Implemented as an injectable clock so it's deterministic in tests.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/services/audio_service.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/services/audio_service_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/services/audio_service_test.dart` and replace its entire contents with:

```dart
import 'dart:io';

import 'package:alaif/services/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the real slice SFX asset is bundled', () {
    expect(File('assets/audio/slice.mp3').existsSync(), isTrue);
    expect(File('assets/audio/slice.mp3').lengthSync(), greaterThan(0));
  });

  test('preload tolerates missing files and test environments silently',
      () async {
    // bomb/combo/miss intentionally do not exist; in tests even slice.mp3
    // cannot load (no asset bundle/platform audio). Nothing may throw.
    await AudioService().preload();
  });

  test('play never throws, even for missing SFX or with no audio backend',
      () async {
    final service = AudioService();
    service.playSlice();
    service.playBomb();
    service.playCombo();
    service.playMiss();
    // Let any async audio failures surface (they must be swallowed).
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  test('disabled service skips playback without error', () {
    final service = AudioService()..enabled = false;
    service.playSlice();
  });

  test('playSlice within 60ms of the previous call is ignored', () {
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    final played = <String>[];
    final service = AudioServiceForTest(
      now: () => t,
      onPlay: played.add,
    );

    service.playSlice(); // t=0ms -> plays
    t = t.add(const Duration(milliseconds: 30));
    service.playSlice(); // t=30ms -> within cooldown, ignored
    t = t.add(const Duration(milliseconds: 40));
    service.playSlice(); // t=70ms since last *played* call -> plays

    expect(played, ['slice.mp3', 'slice.mp3']);
  });

  test('playSlice cooldown does not affect other SFX', () {
    var t = DateTime(2026, 1, 1, 12, 0, 0);
    final played = <String>[];
    final service = AudioServiceForTest(
      now: () => t,
      onPlay: played.add,
    );

    service.playSlice(); // t=0ms -> plays
    service.playBomb(); // different SFX, always plays
    t = t.add(const Duration(milliseconds: 10));
    service.playCombo(); // different SFX, always plays

    expect(played, ['slice.mp3', 'bomb.mp3', 'combo.mp3']);
  });
}

/// Test double that bypasses FlameAudio entirely and records every SFX name
/// that actually reached playback (i.e. was not cooled down / disabled).
class AudioServiceForTest extends AudioService {
  AudioServiceForTest({required DateTime Function() now, required this.onPlay})
      : super(now: now);

  final void Function(String sfx) onPlay;

  @override
  void playInternal(String sfx) => onPlay(sfx);
}
```

- [ ] Run it and confirm it fails to compile (no `now` constructor param, no `playInternal`, no cooldown):

```
cd /Users/iammoo/code/alaif/app && flutter test test/services/audio_service_test.dart 2>&1 | tail -40
```

  Expected: a compile error referencing `now` and/or `playInternal` not being defined on `AudioService`.

- [ ] Implement the minimal fix. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/services/audio_service.dart` with:

```dart
import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

/// SFX wrapper around flame_audio.
///
/// EVERY failure here is non-fatal and silent by design: bomb/combo/miss
/// files don't exist yet (stubs awaiting real CC0 sounds), test environments
/// have no audio backend, and a lost sound must never crash gameplay.
/// [enabled] is driven by the persisted settings.
class AudioService {
  AudioService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  bool enabled = true;

  static const sliceSfx = 'slice.mp3'; // real, bundled
  static const bombSfx = 'bomb.mp3'; // stub — may be missing
  static const comboSfx = 'combo.mp3'; // stub — may be missing
  static const missSfx = 'miss.mp3'; // stub — may be missing

  /// Minimum gap between two `playSlice()` calls that actually play. Guards
  /// against overlapping audio if a single swipe slices the same letter (or
  /// produces multiple slice events) within one frame/gesture-tick.
  static const sliceCooldown = Duration(milliseconds: 60);

  final DateTime Function() _now;
  DateTime? _lastSliceAt;

  /// Warm the cache. flame_audio resolves names under assets/audio/.
  Future<void> preload() async {
    for (final sfx in const [sliceSfx, bombSfx, comboSfx, missSfx]) {
      try {
        await FlameAudio.audioCache.load(sfx);
      } catch (_) {
        // Missing or unloadable SFX: fine, play() will also no-op.
      }
    }
  }

  void _play(String sfx) {
    if (!enabled) return;
    playInternal(sfx);
  }

  /// Performs the actual playback. Split out so tests can override it
  /// without touching FlameAudio (which has no backend in test environments).
  void playInternal(String sfx) {
    try {
      unawaited(
        FlameAudio.play(sfx).then<void>((_) {}).catchError((_) {}),
      );
    } catch (_) {
      // Synchronous audio failures are equally non-fatal.
    }
  }

  void playSlice() {
    if (!enabled) return;
    final now = _now();
    final last = _lastSliceAt;
    if (last != null && now.difference(last) < sliceCooldown) return;
    _lastSliceAt = now;
    playInternal(sliceSfx);
  }

  void playBomb() => _play(bombSfx);
  void playCombo() => _play(comboSfx);
  void playMiss() => _play(missSfx);
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/services/audio_service_test.dart 2>&1 | tail -20
```

  Expected: all tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/services/audio_service.dart test/services/audio_service_test.dart && git commit -m "fix: add 60ms cooldown to AudioService.playSlice to prevent overlapping SFX"
```

---

## Task 3: Edge-to-edge `SystemChrome` + remove `SafeArea` around `GameWidget`

Makes the game canvas paint behind the status bar / notch / gesture nav so there's no white strip, while keeping the scaffold background matching the paper canvas as a fallback for any transient unpainted edge.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/main.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/ui/app_theme_test.dart`

### Steps

- [ ] Write a failing test. Replace the entire contents of `/Users/iammoo/code/alaif/app/test/ui/app_theme_test.dart` with:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/main.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('AlaifApp installs the Ink & Paper theme', (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.theme!.scaffoldBackgroundColor, AlaifColors.paper);
    expect(app.theme!.colorScheme.primary, AlaifColors.ink);
  });

  testWidgets('AlaifApp scaffold paints the paper background edge-to-edge',
      (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AlaifColors.paper);
  });

  testWidgets('AlaifApp does not wrap the GameWidget in a SafeArea',
      (tester) async {
    await tester.pumpWidget(const AlaifApp());
    await tester.pump();

    // The game canvas itself must not be inset by SafeArea so it paints
    // edge-to-edge; insets are instead passed into the game for HUD layout.
    // Overlays (e.g. the menu, shown by default) may still have their own
    // SafeArea, so check specifically that GameWidget has no SafeArea
    // ancestor rather than asserting no SafeArea exists anywhere.
    expect(
      find.ancestor(
        of: find.byType(GameWidget<AlaifGame>),
        matching: find.byType(SafeArea),
      ),
      findsNothing,
    );
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/app_theme_test.dart 2>&1 | tail -40
```

  Expected: the `does not wrap the game in a SafeArea` test fails because `main.dart` currently wraps `GameWidget` in `SafeArea` (and the `Scaffold` test may already pass if `Scaffold` has no explicit `backgroundColor` — `Scaffold.backgroundColor` defaults to `null`, which is NOT `AlaifColors.paper`, so this test should also fail until `backgroundColor` is set explicitly).

- [ ] Implement the minimal fix. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/main.dart` with:

```dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/alaif_game.dart';
import 'ui/alaif_theme.dart';
import 'ui/controls_overlay.dart';
import 'ui/design_tokens.dart';
import 'ui/game_over_overlay.dart';
import 'ui/how_to_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/settings_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const AlaifApp());
}

class AlaifApp extends StatelessWidget {
  const AlaifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlaifTheme(),
      home: Scaffold(
        backgroundColor: AlaifColors.paper,
        body: GameWidget<AlaifGame>.controlled(
          gameFactory: AlaifGame.new,
          overlayBuilderMap: {
            'menu': (context, game) => MenuOverlay(game: game),
            'gameOver': (context, game) => GameOverOverlay(game: game),
            'paused': (context, game) => PauseOverlay(game: game),
            'controls': (context, game) => ControlsOverlay(game: game),
            'howTo': (context, game) => HowToOverlay(game: game),
            'settings': (context, game) => SettingsOverlay(game: game),
          },
        ),
      ),
    );
  }
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/app_theme_test.dart 2>&1 | tail -20
```

  Expected: all 3 tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/main.dart test/ui/app_theme_test.dart && git commit -m "fix: edge-to-edge system UI mode and remove SafeArea around GameWidget"
```

---

## Task 4: Pass safe-area insets into the game and offset the HUD

With `SafeArea` removed in Task 3, the HUD's score (top-left) and lives dots (top-right) can sit under the status bar / notch on devices with cutouts. This task threads `MediaQuery` padding into `AlaifGame` as a settable field and has `Hud` offset its top content by it.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/hud.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/main.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/hud_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/game/hud_test.dart` and replace its entire contents with:

```dart
import 'dart:ui' as ui;

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/hud.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart' show EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('hud covers the screen and tracks the score text',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    expect(hud.size, game.size);
    expect(hud.scoreText, '0');

    game.scoreState.registerHit(); // +10
    expect(hud.scoreText, '10');
  });

  testWithGame<AlaifGame>('lives dots fill while alive and hollow when lost',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    expect(hud.dotFilled(0), isTrue);
    expect(hud.dotFilled(1), isTrue);
    expect(hud.dotFilled(2), isTrue);

    game.rules.onBombSliced(); // 2 lives left
    expect(hud.dotFilled(0), isTrue);
    expect(hud.dotFilled(1), isTrue);
    expect(hud.dotFilled(2), isFalse);
  });

  testWithGame<AlaifGame>('hud render does not throw', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;
    final recorder = ui.PictureRecorder();
    hud.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });

  testWithGame<AlaifGame>('game.safePadding defaults to zero',
      AlaifGame.new, (game) async {
    expect(game.safePadding, EdgeInsets.zero);
  });

  testWithGame<AlaifGame>(
      'hud score origin is offset by game.safePadding top and left',
      AlaifGame.new, (game) async {
    game.safePadding = const EdgeInsets.only(top: 40, left: 20, right: 10);
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;

    expect(hud.scoreOrigin, Vector2(AlaifSpacing.xl + 20, AlaifSpacing.lg + 40));
  });

  testWithGame<AlaifGame>(
      'hud lives-dot row is offset by game.safePadding top and right',
      AlaifGame.new, (game) async {
    game.safePadding = const EdgeInsets.only(top: 40, left: 20, right: 10);
    game.startGame();
    game.update(0);
    final hud = game.children.whereType<Hud>().single;

    expect(hud.livesRowRight, game.size.x - AlaifSpacing.xl - 10);
    expect(hud.livesRowCenterY, AlaifSpacing.lg + 14 + 40);
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/hud_test.dart 2>&1 | tail -40
```

  Expected: compile errors — `AlaifGame` has no `safePadding` getter/setter, and `Hud` has no `scoreOrigin`/`livesRowRight`/`livesRowCenterY`.

- [ ] Implement the minimal fix in `AlaifGame`. In `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`, add the `safePadding` field. The class currently starts:

```dart
class AlaifGame extends FlameGame {
  AlaifGame({
    HighScoreStore? highScores,
    AudioService? audio,
    HapticsService? haptics,
    SettingsStore? settings,
    Random? random,
  })  : highScores = highScores ?? HighScoreStore(),
        audio = audio ?? AudioService(),
        haptics = haptics ?? HapticsService(),
        settings = settings ?? SettingsStore(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();
```

  Change it to:

```dart
class AlaifGame extends FlameGame {
  AlaifGame({
    HighScoreStore? highScores,
    AudioService? audio,
    HapticsService? haptics,
    SettingsStore? settings,
    Random? random,
  })  : highScores = highScores ?? HighScoreStore(),
        audio = audio ?? AudioService(),
        haptics = haptics ?? HapticsService(),
        settings = settings ?? SettingsStore(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();

  /// Device safe-area insets (notch/status bar/gesture nav), set from
  /// `MediaQuery` by the widget that builds the `GameWidget`. Used by [Hud]
  /// to keep score/lives clear of screen cutouts now that the game canvas
  /// paints edge-to-edge (no `SafeArea` ancestor).
  EdgeInsets safePadding = EdgeInsets.zero;
```

  Add the import for `EdgeInsets`. The current imports include:

```dart
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, SizedBox;
```

  Change the second line to:

```dart
import 'package:flutter/widgets.dart' show AppLifecycleState, EdgeInsets, SizedBox;
```

- [ ] Implement the minimal fix in `Hud`. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/hud.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/game_rules.dart';
import '../core/score_format.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// In-game HUD (spec §4.3): "SCORE" label + comma-grouped score top-left,
/// lives top-right as three 14px dots (filled ink = alive, hairline ring =
/// lost). Sits under the blade (priority 90 < 100).
///
/// The game canvas now paints edge-to-edge (no `SafeArea` ancestor), so the
/// HUD offsets its top-left/top-right anchors by [AlaifGame.safePadding].
class Hud extends PositionComponent with HasGameReference<AlaifGame> {
  Hud() : super(priority: 90);

  static const dotRadius = 7.0; // 14px dots
  static const dotGap = 24.0;

  static final TextPaint _labelPaint = TextPaint(style: AlaifType.label);
  static final TextPaint _scorePaint = TextPaint(style: AlaifType.scoreHud);

  String get scoreText => formatScore(game.scoreState.score);

  /// Dot [index] (0..2, left to right) is filled while that life remains.
  bool dotFilled(int index) => index < game.rules.lives;

  /// Top-left origin of the "SCORE" label, after safe-area insets.
  Vector2 get scoreOrigin => Vector2(
        AlaifSpacing.xl + game.safePadding.left,
        AlaifSpacing.lg + game.safePadding.top,
      );

  /// X position of the rightmost lives dot, after safe-area insets.
  double get livesRowRight =>
      size.x - AlaifSpacing.xl - game.safePadding.right;

  /// Y position (vertical center) of the lives-dot row, after safe-area insets.
  double get livesRowCenterY =>
      AlaifSpacing.lg + 14 + game.safePadding.top;

  @override
  void onLoad() {
    position = Vector2.zero();
    size = game.size.clone();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void render(ui.Canvas canvas) {
    // Score block, top-left.
    final origin = scoreOrigin;
    _labelPaint.render(canvas, 'SCORE', origin);
    _scorePaint.render(canvas, scoreText, Vector2(origin.x, origin.y + 18));

    // Lives dots, top-right.
    final cy = livesRowCenterY;
    final right = livesRowRight;
    for (var i = 0; i < GameRules.startingLives; i++) {
      final cx = right - (GameRules.startingLives - 1 - i) * dotGap;
      if (dotFilled(i)) {
        canvas.drawCircle(
          ui.Offset(cx, cy),
          dotRadius,
          ui.Paint()..color = AlaifColors.ink,
        );
      } else {
        canvas.drawCircle(
          ui.Offset(cx, cy),
          dotRadius,
          ui.Paint()
            ..color = AlaifColors.hairline
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }
}
```

- [ ] Wire `safePadding` from `main.dart`. Open `/Users/iammoo/code/alaif/app/lib/main.dart`. The current `build` method is:

```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlaifTheme(),
      home: Scaffold(
        backgroundColor: AlaifColors.paper,
        body: GameWidget<AlaifGame>.controlled(
          gameFactory: AlaifGame.new,
          overlayBuilderMap: {
            'menu': (context, game) => MenuOverlay(game: game),
            'gameOver': (context, game) => GameOverOverlay(game: game),
            'paused': (context, game) => PauseOverlay(game: game),
            'controls': (context, game) => ControlsOverlay(game: game),
            'howTo': (context, game) => HowToOverlay(game: game),
            'settings': (context, game) => SettingsOverlay(game: game),
          },
        ),
      ),
    );
  }
```

  Change it to:

```dart
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlaifTheme(),
      home: Scaffold(
        backgroundColor: AlaifColors.paper,
        body: Builder(
          builder: (context) {
            final padding = MediaQuery.paddingOf(context);
            return GameWidget<AlaifGame>.controlled(
              gameFactory: () => AlaifGame()..safePadding = padding,
              overlayBuilderMap: {
                'menu': (context, game) => MenuOverlay(game: game),
                'gameOver': (context, game) => GameOverOverlay(game: game),
                'paused': (context, game) => PauseOverlay(game: game),
                'controls': (context, game) => ControlsOverlay(game: game),
                'howTo': (context, game) => HowToOverlay(game: game),
                'settings': (context, game) => SettingsOverlay(game: game),
              },
            );
          },
        ),
      ),
    );
  }
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/hud_test.dart 2>&1 | tail -30
```

  Expected: all 5 tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/alaif_game.dart lib/game/hud.dart lib/main.dart test/game/hud_test.dart && git commit -m "fix: thread safe-area insets into the game and offset HUD top anchors"
```

---

## Task 5: Atlas ink-rect scan in `GlyphAtlas`

Pixel-scans each rendered glyph texture for its tight ink bounding box, so later tasks can size the hit circle and cut line from actual ink rather than the font-metric box. Falls back to the full image bounds on scan failure or an empty result.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart` and replace its entire contents with:

```dart
import 'dart:ui' as ui;

import 'package:alaif/core/glyph_atlas.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a single glyph to a non-empty image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
  });

  test('glyph texture includes the spec padding on both axes', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    // Texture = glyph box + 2 * texturePadding; the glyph itself is at least
    // a few px wide, so the image must clearly exceed the padding alone.
    expect(image.width, greaterThan((AlaifGlyph.texturePadding * 2).toInt()));
    expect(image.height, greaterThan((AlaifGlyph.texturePadding * 2).toInt()));
  });

  test('glyph pixels are ink, not the old gold gradient', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final data = (await image.toByteData())!; // rawRgba: r,g,b,a per pixel
    var inkFound = false;
    var goldFound = false;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final a = data.getUint8(i + 3);
      if (a > 200 && r < 0x40 && g < 0x40) inkFound = true;
      if (a > 200 && r > 0xE0 && g > 0x90) goldFound = true; // 0xFFFFD97A-ish
    }
    expect(inkFound, isTrue, reason: 'expected near-black ink pixels');
    expect(goldFound, isFalse, reason: 'old gold gradient should be gone');
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

  test('scanInkRect finds a tight, non-empty rect strictly inside a real glyph image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final rect = await GlyphAtlas.scanInkRect(image);

    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
    // The ink rect must be strictly smaller than the full padded texture
    // (padding + shadow + gradient surround the glyph on all sides).
    expect(rect.width, lessThan(image.width.toDouble()));
    expect(rect.height, lessThan(image.height.toDouble()));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(image.width.toDouble()));
    expect(rect.bottom, lessThanOrEqualTo(image.height.toDouble()));
  });

  test('scanInkRect falls back to full image bounds for a fully transparent image', () async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder); // draw nothing -> fully transparent 10x20 image
    final image = await recorder.endRecording().toImage(10, 20);

    final rect = await GlyphAtlas.scanInkRect(image);
    expect(rect, ui.Rect.fromLTWH(0, 0, 10, 20));
  });

  test('scanInkRect finds the known ink region of a synthetic image', () async {
    // 20x20 fully transparent image with a 4x4 fully-opaque white square at
    // (8,8)-(12,12).
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(8, 8, 4, 4),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    final image = await recorder.endRecording().toImage(20, 20);

    final rect = await GlyphAtlas.scanInkRect(image);
    expect(rect, ui.Rect.fromLTWH(8, 8, 4, 4));
  });

  test('inkRectFor returns a rect for every letter after load', () async {
    final atlas = GlyphAtlas();
    await atlas.load();
    for (final letter in GlyphAtlas.letters) {
      final rect = atlas.inkRectFor(letter);
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    }
  });

  test('inkRectFor throws before load', () {
    expect(() => GlyphAtlas().inkRectFor('ب'), throwsStateError);
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart 2>&1 | tail -40
```

  Expected: compile errors — `GlyphAtlas.scanInkRect` and `inkRectFor` don't exist.

- [ ] Implement the minimal fix. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart` with:

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to textures at load.
///
/// Ink & Paper: glyphs render in ArefRuqaa at [AlaifGlyph.renderFontSize]
/// with the vertical ink gradient [AlaifGradients.glyph] and a soft baked
/// drop shadow, padded by [AlaifGlyph.texturePadding] so nothing clips.
///
/// At load time, each glyph image is also pixel-scanned for its tight "ink
/// rect" — the bounding box of opaque-enough pixels — so [LetterComponent]
/// can size its hit circle and cut line from actual ink rather than the
/// font-metric box (which is unevenly filled for Arabic glyphs).
class GlyphAtlas {
  static const letters = [
    'ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
    'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
    'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
  ];

  /// Alpha (0-255) above which a pixel counts as "ink" for [scanInkRect].
  /// The baked shadow ([AlaifGlyph.shadowColor]) has alpha ~46, well below
  /// this; the glyph fill is fully opaque (alpha 255).
  static const inkAlphaThreshold = 128;

  final Map<String, ui.Image> _images = {};
  final Map<String, ui.Rect> _inkRects = {};

  ui.Image imageFor(String letter) {
    final image = _images[letter];
    if (image == null) {
      throw StateError('GlyphAtlas.load() must complete before imageFor("$letter")');
    }
    return image;
  }

  /// The tight ink bounding box for [letter], in texture-pixel coordinates
  /// relative to the top-left of [imageFor]'s image.
  ui.Rect inkRectFor(String letter) {
    final rect = _inkRects[letter];
    if (rect == null) {
      throw StateError('GlyphAtlas.load() must complete before inkRectFor("$letter")');
    }
    return rect;
  }

  Future<void> load({
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    if (_images.isNotEmpty) return; // idempotent — images are native resources
    for (final letter in letters) {
      final image =
          await renderGlyph(letter, fontSize: fontSize, fontFamily: fontFamily);
      _images[letter] = image;
      _inkRects[letter] = await scanInkRect(image);
    }
  }

  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const pad = AlaifGlyph.texturePadding;
    // Layout once without paint to measure the true glyph box.
    final measure = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(fontSize: fontSize, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final glyphHeight = math.max(measure.height, fontSize);

    // Pass 1 — soft baked shadow (cheap depth on paper).
    final shadowPaint = Paint()
      ..color = AlaifGlyph.shadowColor
      ..maskFilter =
          const ui.MaskFilter.blur(ui.BlurStyle.normal, AlaifGlyph.shadowBlur);
    final shadowPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          foreground: shadowPaint,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    shadowPainter.paint(
      canvas,
      const Offset(pad, pad + AlaifGlyph.shadowOffsetY),
    );

    // Pass 2 — the ink glyph with its vertical gradient.
    final foreground = Paint()
      ..shader = AlaifGradients.glyph.createShader(
        Rect.fromLTWH(pad, pad, math.max(measure.width, 1), glyphHeight),
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
    painter.paint(canvas, const Offset(pad, pad));

    final width = math.max(1, (painter.width + pad * 2).ceil());
    final height = math.max(1, (painter.height + pad * 2).ceil());
    return recorder.endRecording().toImage(width, height);
  }

  /// Scans [image] for the tight bounding box of pixels with alpha greater
  /// than [inkAlphaThreshold]. Falls back to the full image bounds
  /// (`Rect.fromLTWH(0, 0, image.width, image.height)`) if the byte data is
  /// unavailable or no pixel exceeds the threshold.
  static Future<ui.Rect> scanInkRect(
    ui.Image image, {
    int alphaThreshold = inkAlphaThreshold,
  }) async {
    final fallback =
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final ByteData? data;
    try {
      data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } catch (_) {
      return fallback;
    }
    if (data == null) return fallback;

    final width = image.width;
    final height = image.height;
    var minX = width;
    var minY = height;
    var maxX = -1;
    var maxY = -1;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final alphaIndex = (y * width + x) * 4 + 3;
        if (data.getUint8(alphaIndex) > alphaThreshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) return fallback; // nothing above threshold

    return ui.Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart 2>&1 | tail -40
```

  Expected: all tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/core/glyph_atlas.dart test/core/glyph_atlas_test.dart && git commit -m "feat: scan glyph textures for tight ink rects in GlyphAtlas"
```

---

## Task 6: Ink-aware hit circle and `inkCenter` on `LetterComponent`

`LetterComponent` accepts an optional `inkRect` (texture-pixel coordinates, from `GlyphAtlas.inkRectFor`). It scales that rect into local component coordinates and derives `hitRadius` and `inkCenter` from it. When `inkRect` is omitted, behavior matches today exactly (full-image bounds).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/components_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/game/components_test.dart`. The current top of the file is:

```dart
import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ui.Image> testImage({int width = 40, int height = 60}) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImage(width, height);
}
```

  Leave that unchanged. After the existing test `'letter defaults to the max spawn size from the tokens'` (and its closing `});`), add the following new tests:

```dart
  test('letter without an inkRect falls back to full-image hit circle and centered inkCenter', () async {
    final image = await testImage(width: 100, height: 100);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100,
    );
    // No inkRect supplied -> behaves exactly as before (full bbox).
    expect(letter.hitRadius, 50);
    expect(letter.inkCenter, Vector2(50, 50));
  });

  test('letter with an off-center inkRect derives hitRadius and inkCenter from it', () async {
    final image = await testImage(width: 100, height: 100);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100,
      // Ink occupies the top-left quadrant of the 100x100 texture.
      inkRect: const ui.Rect.fromLTWH(0, 0, 40, 20),
    );
    // scale = targetSize / max(image.width, image.height) = 100 / 100 = 1.
    expect(letter.inkCenter, Vector2(20, 10)); // center of (0,0,40,20)
    expect(letter.hitRadius, 20); // max(40, 20) / 2
  });

  test('letter inkRect scales with the component when targetSize differs from texture size', () async {
    final image = await testImage(width: 100, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100, // longest edge (200) -> scale 0.5; size becomes (50, 100)
      // Ink rect in texture-pixel coords: (10,20)-(50,60) -> 40x40.
      inkRect: const ui.Rect.fromLTWH(10, 20, 40, 40),
    );
    // scale = 100 / 200 = 0.5
    expect(letter.size, Vector2(50, 100));
    expect(letter.inkCenter, Vector2((10 + 20) * 0.5, (20 + 20) * 0.5)); // center (30,40) * 0.5 = (15,20)
    expect(letter.hitRadius, 40 * 0.5 / 2); // max(40,40) * 0.5 / 2 = 10
  });
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -40
```

  Expected: compile errors — `LetterComponent` has no `inkRect` parameter or `inkCenter` getter.

- [ ] Implement the minimal fix. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart` with:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
    double targetSize = AlaifGlyph.spawnSizeMax,
    ui.Rect? inkRect,
  }) : _image = image {
    final longest = math.max(image.width, image.height).toDouble();
    final scale = targetSize / longest;
    size = Vector2(image.width * scale, image.height * scale);
    anchor = Anchor.center;
    position = motion.positionAt(0);

    final rect = inkRect ??
        ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    _inkCenter = Vector2(
      (rect.left + rect.right) / 2 * scale,
      (rect.top + rect.bottom) / 2 * scale,
    );
    _hitRadius = math.max(rect.width, rect.height) * scale / 2;
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;
  late final Vector2 _inkCenter;
  late final double _hitRadius;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  /// Set the instant this letter is sliced, before `removeFromParent()` takes
  /// effect (which Flame defers to the next update tick). Prevents a single
  /// swipe's later drag-update segments from re-slicing the same letter.
  bool sliced = false;

  ui.Image get image => _image;

  /// Center of the glyph's ink, in local component coordinates (0..size).
  /// Falls back to the geometric center of [size] when no `inkRect` was
  /// supplied at construction.
  Vector2 get inkCenter => _inkCenter;

  /// Circular hit approximation centered on [inkCenter], sized from the
  /// glyph's ink bounding box (or the full bbox if no `inkRect` was supplied).
  double get hitRadius => _hitRadius;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
    angle += 0.5 * dt; // gentle tumble
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint(),
    );
  }
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -40
```

  Expected: all tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/letter_component.dart test/game/components_test.dart && git commit -m "feat: derive LetterComponent hitRadius and inkCenter from glyph ink rect"
```

---

## Task 7: Wire spawner + game to pass `inkRect` from the atlas

`Spawner` now passes `game.atlas.inkRectFor(letter)` to `LetterComponent`, and `_sliceLetter` uses `letter.inkCenter` (in world coordinates) as the ink-burst origin instead of `letter.position`.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/spawner.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/spawner_test.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`

### Steps

- [ ] Read the current spawner test to match its style:

```
cd /Users/iammoo/code/alaif/app && cat test/game/spawner_test.dart
```

- [ ] Write a failing test. Open `/Users/iammoo/code/alaif/app/test/game/spawner_test.dart` and add the following test inside `void main() { ... }`, after any existing tests (before the final closing `}`):

```dart
  testWithGame<AlaifGame>('spawned letters carry an inkRect-derived hitRadius smaller than the full bbox',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0); // flush Spawner addition
    final spawner = game.children.whereType<Spawner>().single;
    spawner.update(10); // force at least one spawn regardless of curve timing
    game.update(0); // flush spawned letter addition

    final letters = game.children.whereType<LetterComponent>().toList();
    expect(letters, isNotEmpty);
    for (final letter in letters) {
      // Full-bbox hit radius would be letter.size.x / 2; ink-derived radius
      // must be <= that (it can equal it only if the glyph's ink rect
      // happens to span the full texture, which none of the 28 letters do).
      expect(letter.hitRadius, lessThanOrEqualTo(letter.size.x / 2));
      expect(letter.hitRadius, greaterThan(0));
    }
  });
```

  Add the necessary imports at the top of the file if not already present — open the file first and check; it must import:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/spawner.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

  Add only the imports that are missing (do not duplicate existing ones), preserving the rest of the file's existing content (including its `setUp`/`TestWidgetsFlutterBinding.ensureInitialized()` and any existing tests).

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/spawner_test.dart 2>&1 | tail -40
```

  Expected: the new test fails because `LetterComponent.hitRadius` still equals `size.x / 2` (no `inkRect` is passed by `Spawner` yet).

- [ ] Implement the minimal fix in `Spawner`. In `/Users/iammoo/code/alaif/app/lib/game/spawner.dart`, the current letter-spawn block is:

```dart
    if (_random.nextDouble() < _curve.bombChance(_elapsed)) {
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
      ));
    }
```

  Change it to:

```dart
    if (_random.nextDouble() < _curve.bombChance(_elapsed)) {
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
        inkRect: game.atlas.inkRectFor(letter),
      ));
    }
```

- [ ] Implement the minimal fix in `AlaifGame._sliceLetter`. Open `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. The current `_sliceLetter` is:

```dart
  void _sliceLetter(LetterComponent letter) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    _lastSlicePosition = letter.position.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(letter.position, _random),
    ));
    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(-120, -150),
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(120, -100),
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
  }
```

  Change it to:

```dart
  void _sliceLetter(LetterComponent letter) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    // World-space ink center: position is the bbox center (anchor.center),
    // so top-left is (position - size/2); inkCenter is local (0..size).
    final inkCenterWorld =
        letter.position - letter.size / 2 + letter.inkCenter;
    _lastSlicePosition = inkCenterWorld.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(inkCenterWorld, _random),
    ));
    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(-120, -150),
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(120, -100),
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
  }
```

- [ ] Update `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`'s `staticLetter` helper so it also carries an `inkRect` (matching real spawns) and so existing position-based assertions on `_lastSlicePosition`/burst positions remain meaningful. The current helper is:

```dart
LetterComponent staticLetter(AlaifGame game, {double x = 100, double y = 300}) {
  return LetterComponent(
    letter: 'ب',
    image: game.atlas.imageFor('ب'),
    motion: ArcMotion(start: Vector2(x, y), velocity: Vector2.zero(), gravity: 0),
  );
}
```

  Change it to:

```dart
LetterComponent staticLetter(AlaifGame game, {double x = 100, double y = 300}) {
  return LetterComponent(
    letter: 'ب',
    image: game.atlas.imageFor('ب'),
    motion: ArcMotion(start: Vector2(x, y), velocity: Vector2.zero(), gravity: 0),
    inkRect: game.atlas.inkRectFor('ب'),
  );
}
```

- [ ] Run the targeted tests again and confirm they pass:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/spawner_test.dart test/game/alaif_game_test.dart 2>&1 | tail -60
```

  Expected: all tests in both files pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/spawner.dart lib/game/alaif_game.dart test/game/spawner_test.dart test/game/alaif_game_test.dart && git commit -m "feat: spawn letters with ink rects and burst from ink center on slice"
```

---

## Task 8: Half-plane clip geometry on `SlicedHalf`

Replaces the fixed horizontal-bisection clip with a half-plane `Path` clip through a given local cut center, along a given cut direction. Adds a static, independently-testable `halfPlanePath` helper.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/components_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/game/components_test.dart` and add the following tests inside `void main() { ... }`, after the three new `LetterComponent` ink-rect tests added in Task 6 (before the existing `testWithGame<AlaifGame>('sliced half is removed after cutHalfTumbleMs', ...)` test, or anywhere else inside `main()` — placement among tests does not matter, only that they are inside `main()`):

```dart
  group('SlicedHalf.halfPlanePath', () {
    test('horizontal cut through center: positive side keeps the bottom half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(1, 0), // horizontal line y=50
        keepPositiveSide: true, // normal = (0,1) -> positive side is y > 50
      );
      expect(path.contains(const ui.Offset(50, 90)), isTrue); // below the line
      expect(path.contains(const ui.Offset(50, 10)), isFalse); // above the line
    });

    test('horizontal cut through center: negative side keeps the top half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(1, 0),
        keepPositiveSide: false,
      );
      expect(path.contains(const ui.Offset(50, 10)), isTrue); // above the line
      expect(path.contains(const ui.Offset(50, 90)), isFalse); // below the line
    });

    test('vertical cut through center: positive side keeps the right half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(0, 1), // vertical line x=50
        keepPositiveSide: true, // normal = (-1,0) -> positive side is x < 50... see below
      );
      // For direction (0,1), normal = (-dy, dx) = (-1, 0), so the positive
      // side ((p-c) dot normal >= 0) is x <= 50 (the left half).
      expect(path.contains(const ui.Offset(10, 50)), isTrue); // left
      expect(path.contains(const ui.Offset(90, 50)), isFalse); // right
    });

    test('off-center cut point shifts the dividing line', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 20), // line y=20
        cutDirection: Vector2(1, 0),
        keepPositiveSide: true, // y > 20
      );
      expect(path.contains(const ui.Offset(50, 50)), isTrue); // y=50 > 20
      expect(path.contains(const ui.Offset(50, 5)), isFalse); // y=5 < 20
    });
  });

  testWithGame<AlaifGame>('sliced half with cut geometry renders without throwing',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000,
      cutCenter: Vector2(20, 30),
      cutDirection: Vector2(1, 0),
    );
    await game.add(half);
    game.update(0);

    final recorder = ui.PictureRecorder();
    half.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -50
```

  Expected: compile errors — `SlicedHalf.halfPlanePath` doesn't exist, and the `SlicedHalf` constructor has no `cutCenter`/`cutDirection` parameters.

- [ ] Implement the minimal fix. Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';

/// One half of a sliced glyph, clipped from the full texture along the
/// swipe's cut line, tumbling away.
///
/// Removed when it falls past [removeBelowY] OR after
/// [AlaifMotion.cutHalfTumbleMs], whichever comes first.
class SlicedHalf extends PositionComponent {
  SlicedHalf({
    required ui.Image image,
    required Vector2 startPosition,
    required Vector2 velocity,
    required this.topHalf,
    required this.removeBelowY,
    Vector2? displaySize,
    Vector2? cutCenter,
    Vector2? cutDirection,
  })  : _image = image,
        _velocity = velocity.clone() {
    size = displaySize?.clone() ??
        Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = startPosition.clone();

    // Default cut: horizontal line through the component's center, matching
    // the previous fixed-bisection behavior when no swipe geometry is given.
    _cutCenter = cutCenter?.clone() ?? Vector2(size.x / 2, size.y / 2);
    final dir = cutDirection?.clone() ?? Vector2(1, 0);
    _cutDirection = dir.length2 > 0 ? (dir..normalize()) : Vector2(1, 0);
  }

  static const gravity = 900.0;
  static const spin = 3.0;

  /// How far the half-plane clip quad extends beyond the component's bounds,
  /// as a multiple of (size.x + size.y), so it always fully covers [size]
  /// regardless of where [cutCenter] sits within it.
  static const _clipExtentFactor = 4.0;

  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;
  late final Vector2 _cutCenter;
  late final Vector2 _cutDirection;
  double _ageMs = 0;

  @override
  void update(double dt) {
    _ageMs += dt * 1000;
    _velocity.y += gravity * dt;
    position += _velocity * dt;
    angle += (topHalf ? -spin : spin) * dt;
    if (position.y > removeBelowY || _ageMs >= AlaifMotion.cutHalfTumbleMs) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final clip = halfPlanePath(
      size: size,
      cutCenter: _cutCenter,
      cutDirection: _cutDirection,
      keepPositiveSide: topHalf,
    );
    canvas.save();
    canvas.clipPath(clip);
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint(),
    );
    canvas.restore();
  }

  /// Builds a `Path` covering one half-plane of an (effectively infinite)
  /// line through [cutCenter] with direction [cutDirection] (need not be
  /// normalized; will be normalized internally).
  ///
  /// The line's normal is `(-cutDirection.y, cutDirection.x)`. A point [p] is
  /// on the "positive" side when `(p - cutCenter) dot normal >= 0`.
  /// [keepPositiveSide] selects which side the returned path covers.
  ///
  /// The path is a quad extended far beyond [size] in both directions along
  /// the line and the chosen normal direction, so clipping with it against a
  /// canvas of [size] always yields exactly the intended half.
  static ui.Path halfPlanePath({
    required Vector2 size,
    required Vector2 cutCenter,
    required Vector2 cutDirection,
    required bool keepPositiveSide,
  }) {
    final dir = cutDirection.length2 > 0
        ? (cutDirection.clone()..normalize())
        : Vector2(1, 0);
    final normal = Vector2(-dir.y, dir.x);
    final extent = (size.x + size.y) * _clipExtentFactor;
    final normalSign = keepPositiveSide ? 1.0 : -1.0;

    final p1 = cutCenter - dir * extent;
    final p2 = cutCenter + dir * extent;
    final p3 = p2 + normal * (extent * normalSign);
    final p4 = p1 + normal * (extent * normalSign);

    return ui.Path()
      ..moveTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..lineTo(p3.x, p3.y)
      ..lineTo(p4.x, p4.y)
      ..close();
  }
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -60
```

  Expected: all tests in this file pass, including the new `SlicedHalf.halfPlanePath` group and the cut-geometry render test. Note: the existing test `'sliced half falls and removes itself below the cutoff'` and `'sliced half is removed after cutHalfTumbleMs'` construct `SlicedHalf` without `cutCenter`/`cutDirection` — these must still pass via the defaults.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/sliced_halves.dart test/game/components_test.dart && git commit -m "feat: clip SlicedHalf with a half-plane Path along the cut line"
```

---

## Task 9: Thread the swipe segment from `trySlice` into the cut geometry

`trySlice` now passes the swipe's `from`/`to` segment into `_sliceLetter`, which computes the cut direction from it (falling back to horizontal for a degenerate/zero-length segment) and passes `cutCenter` (the letter's local `inkCenter`) and `cutDirection` to both `SlicedHalf`s. The two halves also separate perpendicular to the cut line.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`

### Steps

- [ ] Write failing tests. Open `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`. Ensure the import list includes `dart:ui` and `Vector2`/`SlicedHalf` (already imported via `package:flame/components.dart` and `package:alaif/game/sliced_halves.dart` respectively — check the current imports first):

```
cd /Users/iammoo/code/alaif/app && head -20 test/game/alaif_game_test.dart
```

  If `dart:ui` is not imported, add `import 'dart:ui' as ui;` as the first line of the file. Then add the following test inside `void main() { ... }`, after the `'a letter already sliced this frame is not sliced again by a later segment'` test added in Task 1:

```dart
  testWithGame<AlaifGame>(
      'a vertical swipe produces sliced halves whose cut direction matches the swipe',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0); // mount

    // Vertical swipe (top to bottom) through the letter's position.
    game.trySlice(Vector2(100, 200), Vector2(100, 400));
    game.update(0);

    final halves = game.children.whereType<SlicedHalf>().toList();
    expect(halves.length, 2);
    for (final half in halves) {
      // cutDirection should be (close to) vertical: |y| component dominates.
      expect(half.cutDirection.x.abs(), lessThan(half.cutDirection.y.abs()));
    }
    // The two halves must separate from each other (different velocities).
    expect(halves[0].velocity, isNot(equals(halves[1].velocity)));
  });

  testWithGame<AlaifGame>(
      'a degenerate (zero-length) swipe segment falls back to a horizontal cut',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game);
    game.add(letter);
    game.update(0);

    // from == to: zero-length segment, but it still must hit (radius covers point).
    game.trySlice(Vector2(100, 300), Vector2(100, 300));
    game.update(0);

    final halves = game.children.whereType<SlicedHalf>().toList();
    expect(halves.length, 2);
    for (final half in halves) {
      expect(half.cutDirection, Vector2(1, 0));
    }
  });
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -50
```

  Expected: compile errors — `SlicedHalf` has no public `cutDirection`/`velocity` getters yet (added below), and `_sliceLetter` does not yet vary the cut by swipe direction.

- [ ] Add public getters to `SlicedHalf`. Open `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart`. The current field declarations are:

```dart
  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;
  late final Vector2 _cutCenter;
  late final Vector2 _cutDirection;
  double _ageMs = 0;
```

  Change them to:

```dart
  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;
  late final Vector2 _cutCenter;
  late final Vector2 _cutDirection;
  double _ageMs = 0;

  /// Current tumble velocity (px/s). Exposed for testing the perpendicular
  /// separation of the two halves.
  Vector2 get velocity => _velocity;

  /// Unit vector along the cut line that produced this half.
  Vector2 get cutDirection => _cutDirection;
```

- [ ] Implement the cut-geometry threading in `AlaifGame`. Open `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. The current `trySlice` letter loop is:

```dart
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
```

  Change it to:

```dart
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter, from, to);
      }
    }
```

  Then replace the entire `_sliceLetter` method — currently:

```dart
  void _sliceLetter(LetterComponent letter) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    // World-space ink center: position is the bbox center (anchor.center),
    // so top-left is (position - size/2); inkCenter is local (0..size).
    final inkCenterWorld =
        letter.position - letter.size / 2 + letter.inkCenter;
    _lastSlicePosition = inkCenterWorld.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(inkCenterWorld, _random),
    ));
    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(-120, -150),
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: Vector2(120, -100),
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
    ));
  }
```

  Replace it with:

```dart
  /// Perpendicular separation speed (px/s) the two halves drift apart at,
  /// in addition to their shared upward "pop" velocity.
  static const _halfSeparationSpeed = 150.0;

  /// Shared upward "pop" velocity (px/s) added to both halves' separation.
  static final Vector2 _halfPopVelocity = Vector2(0, -100);

  void _sliceLetter(LetterComponent letter, Vector2 swipeFrom, Vector2 swipeTo) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    // World-space ink center: position is the bbox center (anchor.center),
    // so top-left is (position - size/2); inkCenter is local (0..size).
    final inkCenterWorld =
        letter.position - letter.size / 2 + letter.inkCenter;
    _lastSlicePosition = inkCenterWorld.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(inkCenterWorld, _random),
    ));

    // Cut direction follows the swipe; degenerate (zero-length) segments
    // fall back to a horizontal cut.
    final swipeVector = swipeTo - swipeFrom;
    final cutDirection =
        swipeVector.length2 > 0 ? (swipeVector.clone()..normalize()) : Vector2(1, 0);
    // Halves separate perpendicular to the cut line, plus a shared upward pop.
    final perp = Vector2(-cutDirection.y, cutDirection.x);

    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: perp * _halfSeparationSpeed + _halfPopVelocity,
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
      cutCenter: letter.inkCenter,
      cutDirection: cutDirection,
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: -perp * _halfSeparationSpeed + _halfPopVelocity,
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
      cutCenter: letter.inkCenter,
      cutDirection: cutDirection,
    ));
  }
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart test/game/components_test.dart 2>&1 | tail -60
```

  Expected: all tests in both files pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/alaif_game.dart lib/game/sliced_halves.dart test/game/alaif_game_test.dart && git commit -m "feat: cut letters along the swipe direction through their ink center"
```

---

## Task 10: Final verification — analyze + full suite

No code changes. Confirms the whole branch is clean: static analysis passes and every test (110 original + new ones from Tasks 1-9) is green.

**Files:** none (verification only).

### Steps

- [ ] Run static analysis and confirm there are no issues:

```
cd /Users/iammoo/code/alaif/app && flutter analyze 2>&1 | tail -20
```

  Expected: `No issues found!`

- [ ] Run the full test suite and confirm everything passes:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] If either command reports any issue, fix it in the relevant file from Tasks 1-9 (do not introduce new features), re-run both commands, and only proceed once both are clean.

- [ ] No commit for this task unless a fix was needed in the previous step — if a fix was needed, commit it with:

```
cd /Users/iammoo/code/alaif/app && git add -A && git commit -m "fix: address flutter analyze / test issues from device review 1 fixes"
```
