# Device Review 1 Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three device-review issues in the Alaif Flutter+Flame game — non-full-screen canvas, overlapping slice SFX from duplicate slices, and trivial-sliver letter cuts — while keeping all 110+ existing tests green.

The third fix supersedes the earlier ink-rect pixel-scan approach: each glyph
is now baked onto a slightly-rotated warm **paper carrier card** (deckled
edge, baked shadow, hairline border) as a single composite texture. Hit
circle and cut geometry derive from the card's known square geometry — no
pixel scanning. Cuts pass through the card center along the actual swipe
direction via half-plane `Path` clips; the two halves separate with a
swipe-scaled impulse, plus a brief hit-stop for impact "juice". The hero
glyph font also changes from ArefRuqaa to **Katibeh** (OFL 1.1, Google
Fonts) — a closer open Thuluth-flavored face — and the user's larger spawn
sizes (196–332) are kept.

**Architecture:** `AlaifGame` (Flame `FlameGame`) owns gameplay state and is hosted by `GameWidget` inside `MaterialApp`/`Scaffold` in `main.dart`; `LetterComponent`/`SlicedHalf`/`Hud`/`BladeTrail` are Flame components; `GlyphAtlas` pre-renders the 28 Arabic letters to composite `ui.Image` paper-card textures (card + glyph baked together) at load time, and exposes the card's square side length (in texture pixels) per letter via `cardSizeFor(letter)`; `LetterComponent` derives its hit circle from that card geometry and applies a small per-spawn random rotation; `SlicedHalf` clips the composite texture with a half-plane `Path` through the card center along the swipe direction and separates perpendicular to the cut with a swipe-scaled impulse; `AudioService` wraps `flame_audio`. All visuals use tokens from `lib/ui/design_tokens.dart`, including the new `AlaifCard` token group.

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

## Task 5: Katibeh font swap (replaces ArefRuqaa)

Vendors the Katibeh OFL font (a closer open Thuluth-flavored face than
ArefRuqaa for the hero glyphs), points `AlaifFonts.arabic` at it, and removes
the now-unreferenced ArefRuqaa font files and pubspec entries. This task also
commits the existing **uncommitted** `pubspec.yaml` version bump to
`1.0.0+5` (it is unrelated to this change but has no other natural home in
this plan, so it rides along here).

**Files:**
- Add: `/Users/iammoo/code/alaif/app/assets/fonts/Katibeh-Regular.ttf`
- Add: `/Users/iammoo/code/alaif/app/assets/fonts/OFL-Katibeh.txt`
- Delete: `/Users/iammoo/code/alaif/app/assets/fonts/ArefRuqaa-Regular.ttf`
- Delete: `/Users/iammoo/code/alaif/app/assets/fonts/ArefRuqaa-Bold.ttf`
- Delete: `/Users/iammoo/code/alaif/app/assets/fonts/OFL-ArefRuqaa.txt`
- Modify: `/Users/iammoo/code/alaif/app/pubspec.yaml`
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/ui/font_assets_test.dart`

### Steps

- [ ] Confirm the uncommitted `pubspec.yaml` version bump is present (it was
      made by the user outside this plan and will be committed by this task):

```
cd /Users/iammoo/code/alaif/app && git diff pubspec.yaml
```

  Expected: a diff showing `version: 1.0.0+5` (vs. an older version on the
  previous line). If there is no diff, the version is already committed —
  that's fine, just continue; the final `git add pubspec.yaml` below will
  then be a no-op for that line.

- [ ] Download the Katibeh font and its license file. Run from
      `/Users/iammoo/code/alaif/app`:

```
cd /Users/iammoo/code/alaif/app && curl -fL -o assets/fonts/Katibeh-Regular.ttf https://github.com/google/fonts/raw/main/ofl/katibeh/Katibeh-Regular.ttf && curl -fL -o assets/fonts/OFL-Katibeh.txt https://github.com/google/fonts/raw/main/ofl/katibeh/OFL.txt
```

- [ ] Verify both files downloaded correctly — the font must be a valid
      TrueType file and the license file must be non-empty:

```
cd /Users/iammoo/code/alaif/app && file assets/fonts/Katibeh-Regular.ttf && wc -c assets/fonts/OFL-Katibeh.txt
```

  Expected: `assets/fonts/Katibeh-Regular.ttf: TrueType Font data` (or similar
  mentioning "TrueType"), and a non-zero byte count for `OFL-Katibeh.txt`. If
  `file` reports `HTML document` or similar, the download failed (e.g. GitHub
  raw URL returned an error page) — re-run the `curl` commands and re-check
  before proceeding.

- [ ] Write failing tests. Replace the entire contents of
      `/Users/iammoo/code/alaif/app/test/ui/font_assets_test.dart` with:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontFiles = [
    'assets/fonts/Spectral-Regular.ttf',
    'assets/fonts/Spectral-Italic.ttf',
    'assets/fonts/Spectral-Medium.ttf',
    'assets/fonts/Spectral-MediumItalic.ttf',
    'assets/fonts/Katibeh-Regular.ttf',
    'assets/fonts/OFL-Spectral.txt',
    'assets/fonts/OFL-Katibeh.txt',
  ];

  test('all vendored font files and licenses exist and are non-empty', () {
    for (final path in fontFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(file.lengthSync(), greaterThan(0), reason: '$path is empty');
    }
  });

  test('ArefRuqaa font files are no longer vendored', () {
    for (final path in [
      'assets/fonts/ArefRuqaa-Regular.ttf',
      'assets/fonts/ArefRuqaa-Bold.ttf',
      'assets/fonts/OFL-ArefRuqaa.txt',
    ]) {
      expect(File(path).existsSync(), isFalse,
          reason: '$path should have been removed with the Katibeh swap');
    }
  });

  test('pubspec declares both font families and the Katibeh asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Spectral'));
    expect(pubspec, contains('family: Katibeh'));
    expect(pubspec, contains('assets/fonts/Spectral-MediumItalic.ttf'));
    expect(pubspec, contains('assets/fonts/Katibeh-Regular.ttf'));
    expect(pubspec, isNot(contains('ArefRuqaa')));
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/font_assets_test.dart 2>&1 | tail -40
```

  Expected: `pubspec declares both font families and the Katibeh asset` fails
  (no `family: Katibeh` / `Katibeh-Regular.ttf` in `pubspec.yaml` yet, and it
  still contains `ArefRuqaa`). The `ArefRuqaa font files are no longer
  vendored` test should currently FAIL too (the files still exist) — both
  failures are expected at this point.

- [ ] Implement the minimal fix in `pubspec.yaml`. The current `fonts:` block
      is:

```yaml
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
        - asset: assets/fonts/Spectral-Italic.ttf
          style: italic
        - asset: assets/fonts/Spectral-Medium.ttf
          weight: 500
        - asset: assets/fonts/Spectral-MediumItalic.ttf
          weight: 500
          style: italic
    - family: ArefRuqaa
      fonts:
        - asset: assets/fonts/ArefRuqaa-Regular.ttf
        - asset: assets/fonts/ArefRuqaa-Bold.ttf
          weight: 700
```

  Change it to:

```yaml
  fonts:
    - family: Spectral
      fonts:
        - asset: assets/fonts/Spectral-Regular.ttf
        - asset: assets/fonts/Spectral-Italic.ttf
          style: italic
        - asset: assets/fonts/Spectral-Medium.ttf
          weight: 500
        - asset: assets/fonts/Spectral-MediumItalic.ttf
          weight: 500
          style: italic
    - family: Katibeh
      fonts:
        - asset: assets/fonts/Katibeh-Regular.ttf
```

- [ ] Remove the now-unreferenced ArefRuqaa font files:

```
cd /Users/iammoo/code/alaif/app && git rm -f assets/fonts/ArefRuqaa-Regular.ttf assets/fonts/ArefRuqaa-Bold.ttf assets/fonts/OFL-ArefRuqaa.txt
```

- [ ] Implement the minimal fix in `design_tokens.dart`. In
      `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`, the current
      `AlaifFonts` class is:

```dart
abstract class AlaifFonts {
  static const ui = 'Spectral'; // Latin UI serif
  static const arabic = 'ArefRuqaa'; // calligraphic hero glyph + Arabic accents
}
```

  Change it to:

```dart
abstract class AlaifFonts {
  static const ui = 'Spectral'; // Latin UI serif
  static const arabic = 'Katibeh'; // Thuluth-flavored hero glyph + Arabic accents
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/font_assets_test.dart 2>&1 | tail -20
```

  Expected: all 3 tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit (this also picks up the pre-existing uncommitted
      `pubspec.yaml` version bump to `1.0.0+5`):

```
cd /Users/iammoo/code/alaif/app && git add assets/fonts/Katibeh-Regular.ttf assets/fonts/OFL-Katibeh.txt pubspec.yaml lib/ui/design_tokens.dart test/ui/font_assets_test.dart && git commit -m "feat: swap hero glyph font from ArefRuqaa to Katibeh (OFL)"
```

---

## Task 6: `AlaifCard` design tokens

Adds the token group for the paper carrier card: a slightly brighter paper
fill, hairline edge, deckle amplitude, corner radius, padding factor (glyph
extent → card side), and baked shadow values. This task also commits the
pre-existing **uncommitted** spawn-size change in `design_tokens.dart`
(`spawnSizeMin: 196.0`, `spawnSizeMax: 332.0`) — both are tokens-file changes
and ride together.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/ui/design_tokens_test.dart` (create if it does not exist)

### Steps

- [ ] Confirm the uncommitted spawn-size change is present:

```
cd /Users/iammoo/code/alaif/app && git diff lib/ui/design_tokens.dart
```

  Expected: a diff showing `spawnSizeMin = 196.0` and `spawnSizeMax = 332.0`
  (vs. smaller previous values). If there is no diff, the values are already
  committed at 196/332 — that's fine, continue; the relevant assertions below
  will already pass and the final `git add` will be a no-op for those lines.

- [ ] Check whether `/Users/iammoo/code/alaif/app/test/ui/design_tokens_test.dart`
      already exists:

```
cd /Users/iammoo/code/alaif/app && ls test/ui/ | grep -i design_tokens || echo "NOT FOUND"
```

- [ ] Write failing tests. If the file does **not** exist, create
      `/Users/iammoo/code/alaif/app/test/ui/design_tokens_test.dart` with
      exactly the following contents. If it **does** exist, read it first and
      add these tests inside its existing `void main() { ... }` (do not
      duplicate any existing `import` lines or `main()` wrapper — merge the
      `test(...)` blocks below into the existing file's `main()`):

```dart
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spawn size tokens match the larger device-review-1 spawn sizes', () {
    expect(AlaifGlyph.spawnSizeMin, 196.0);
    expect(AlaifGlyph.spawnSizeMax, 332.0);
    expect(AlaifGlyph.spawnSizeMax, greaterThan(AlaifGlyph.spawnSizeMin));
  });

  test('AlaifCard exposes paper-carrier-card tokens', () {
    // Card fill is a brighter paper than the canvas background, so the card
    // reads as a distinct surface.
    expect(AlaifCard.color, isA<Color>());
    expect(AlaifCard.color, isNot(AlaifColors.paper));

    // Edge hairline reuses the shared hairline ink tone.
    expect(AlaifCard.edgeColor, AlaifColors.hairline);

    // Card side = glyph max extent * paddingFactor; must be > 1 (the card is
    // larger than the bare glyph).
    expect(AlaifCard.paddingFactor, greaterThan(1.0));

    // Deckled-edge wobble amplitude, in texture pixels.
    expect(AlaifCard.deckleAmplitude, greaterThan(0));

    // Corner radius for the card's rounded-rect base shape.
    expect(AlaifCard.cornerRadius, greaterThan(0));

    // Baked shadow values (reuses the same shape as AlaifGlyph's glyph
    // shadow, but for the card itself).
    expect(AlaifCard.shadowColor, isA<Color>());
    expect(AlaifCard.shadowBlur, greaterThan(0));
    expect(AlaifCard.shadowOffsetY, greaterThan(0));

    // Hit-circle radius factor: the inscribed-circle radius of the card is
    // (side / 2) * hitRadiusFactor, slightly generous for forgiving slicing.
    expect(AlaifCard.hitRadiusFactor, greaterThan(0));
    expect(AlaifCard.hitRadiusFactor, lessThanOrEqualTo(1.0));
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/design_tokens_test.dart 2>&1 | tail -40
```

  Expected: compile errors — `AlaifCard` does not exist yet.

- [ ] Implement the minimal fix. In
      `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`, the current
      `AlaifGlyph` class (the last class in the file) is:

```dart
// ---------------------------------------------------------------------------
// GLYPH ATLAS CONFIG  (GlyphAtlas — pre-rendered letter textures)
// ---------------------------------------------------------------------------
abstract class AlaifGlyph {
  /// Font size used when pre-rendering each letter to a ui.Image texture.
  /// Render large for crispness; scale down per-spawn in the component.
  static const renderFontSize = 220.0;

  /// Texture padding so the gradient + faint shadow aren't clipped.
  static const texturePadding = 24.0;

  /// On-screen letter size range (diameter-ish) at spawn.
  static const spawnSizeMin = 196.0;
  static const spawnSizeMax = 332.0;

  /// Soft drop shadow baked into the texture (cheap depth on paper).
  static const shadowBlur = 3.0;
  static const shadowOffsetY = 2.0;
  static const shadowColor = Color(0x2E1B1712); // ~0.18 ink
}
```

  Change it to (adds the new `AlaifCard` class after `AlaifGlyph`; the
  `AlaifGlyph` class itself is unchanged — `spawnSizeMin`/`spawnSizeMax`
  values 196.0/332.0 are already correct from the uncommitted change):

```dart
// ---------------------------------------------------------------------------
// GLYPH ATLAS CONFIG  (GlyphAtlas — pre-rendered letter textures)
// ---------------------------------------------------------------------------
abstract class AlaifGlyph {
  /// Font size used when pre-rendering each letter to a ui.Image texture.
  /// Render large for crispness; scale down per-spawn in the component.
  static const renderFontSize = 220.0;

  /// Texture padding so the gradient + faint shadow aren't clipped.
  static const texturePadding = 24.0;

  /// On-screen letter size range (diameter-ish) at spawn.
  static const spawnSizeMin = 196.0;
  static const spawnSizeMax = 332.0;

  /// Soft drop shadow baked into the texture (cheap depth on paper).
  static const shadowBlur = 3.0;
  static const shadowOffsetY = 2.0;
  static const shadowColor = Color(0x2E1B1712); // ~0.18 ink
}

// ---------------------------------------------------------------------------
// CARRIER CARD  (GlyphAtlas — paper card baked behind each glyph)
// ---------------------------------------------------------------------------
/// Tokens for the paper "carrier card" each glyph is baked onto (device
/// review 1, decision 3): a slightly-rotated warm paper card with a deckled
/// edge, baked shadow, and hairline border. The card is square; its side is
/// `glyphMaxExtent * paddingFactor`. Hit circle and cut geometry derive from
/// this known square geometry — no pixel scanning.
abstract class AlaifCard {
  /// Card fill — slightly brighter than the canvas paper so cards read as
  /// distinct surfaces sitting on top of the background.
  static const color = Color(0xFFF7F1E3);

  /// Hairline border stroked around the card edge.
  static const edgeColor = AlaifColors.hairline;

  /// Card side = glyph max extent (width or height of the rendered glyph,
  /// including its own texture padding) * this factor. > 1 so the card is
  /// visibly larger than the bare glyph.
  static const paddingFactor = 1.35;

  /// Peak outward/inward wobble of the deckled edge, in texture pixels.
  /// The deckle is generated deterministically per letter (seeded by the
  /// letter's position in [GlyphAtlas.letters]) so it is stable across loads.
  static const deckleAmplitude = 6.0;

  /// Number of wobble segments per card edge (deckle "teeth" per side).
  static const deckleSegmentsPerEdge = 5;

  /// Corner radius of the card's base rounded-rect shape (before deckling).
  static const cornerRadius = 18.0;

  /// Soft baked shadow under the card (cheap depth on paper).
  static const shadowColor = Color(0x331B1712); // ~0.20 ink
  static const shadowBlur = 10.0;
  static const shadowOffsetY = 6.0;

  /// The component's hit-circle radius is
  /// `(cardSide * componentScale / 2) * hitRadiusFactor` — the inscribed
  /// circle of the square card, scaled slightly for a forgiving hit area.
  /// 1.0 == exactly the inscribed circle; values > 1.0 would extend past the
  /// card's straight edges, so this stays <= 1.0 ("slightly generous" means
  /// close to 1.0, not over it).
  static const hitRadiusFactor = 0.92;
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/ui/design_tokens_test.dart 2>&1 | tail -20
```

  Expected: both tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit (this also picks up the pre-existing uncommitted spawn-size
      change to `design_tokens.dart`):

```
cd /Users/iammoo/code/alaif/app && git add lib/ui/design_tokens.dart test/ui/design_tokens_test.dart && git commit -m "feat: add AlaifCard paper-carrier-card design tokens"
```

---

## Task 7: Paper-card composite rendering in `GlyphAtlas`

Each glyph texture becomes a single composite `ui.Image`: a deckled-edge
paper card (with baked shadow and hairline border) drawn first, then the
existing two-pass glyph (shadow + gradient) centered on top. The composite
image is square — its side is the card side — so later tasks can derive hit
circle and cut geometry purely from `image.width`/`image.height` (exposed via
`cardSizeFor`), with no pixel scanning.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart`

### Steps

- [ ] Read the current atlas test file to preserve its existing tests:

```
cd /Users/iammoo/code/alaif/app && cat test/core/glyph_atlas_test.dart
```

  (At this point in the plan it should contain the original tests: "renders a
  single glyph to a non-empty image", "glyph texture includes the spec
  padding on both axes", "glyph pixels are ink, not the old gold gradient",
  "atlas exposes all 28 letters", "load makes every letter available",
  "imageFor throws before load". If any ink-rect-related tests from a
  previous draft of this plan exist — e.g. `scanInkRect`, `inkRectFor` — they
  do not exist in this codebase; do not add them.)

- [ ] Write failing tests. Replace the entire contents of
      `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart` with:

```dart
import 'package:alaif/core/glyph_atlas.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a single glyph card to a non-empty square image', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    expect(image.width, greaterThan(0));
    expect(image.height, greaterThan(0));
    // The carrier card is square.
    expect(image.width, image.height);
  });

  test('glyph card includes the spec padding plus card padding factor',
      () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    // Card side = glyph box (>= 2*texturePadding) * paddingFactor, so the
    // composite image must clearly exceed the bare texture padding alone.
    expect(image.width,
        greaterThan((AlaifGlyph.texturePadding * 2 * AlaifCard.paddingFactor).toInt()));
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

  test('glyph card includes the carrier-card paper fill color', () async {
    final image = await GlyphAtlas.renderGlyph('ب');
    final data = (await image.toByteData())!;
    var cardFound = false;
    const cardColor = AlaifCard.color;
    final cardR = (cardColor.r * 255).round();
    final cardG = (cardColor.g * 255).round();
    final cardB = (cardColor.b * 255).round();
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      final a = data.getUint8(i + 3);
      if (a > 200 &&
          (r - cardR).abs() <= 2 &&
          (g - cardG).abs() <= 2 &&
          (b - cardB).abs() <= 2) {
        cardFound = true;
        break;
      }
    }
    expect(cardFound, isTrue,
        reason: 'expected AlaifCard.color paper-fill pixels somewhere on the card');
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

  test('cardSizeFor returns the square card side for every letter after load',
      () async {
    final atlas = GlyphAtlas();
    await atlas.load();
    for (final letter in GlyphAtlas.letters) {
      final side = atlas.cardSizeFor(letter);
      expect(side, greaterThan(0));
      expect(side, atlas.imageFor(letter).width.toDouble());
      expect(side, atlas.imageFor(letter).height.toDouble());
    }
  });

  test('cardSizeFor throws before load', () {
    expect(() => GlyphAtlas().cardSizeFor('ب'), throwsStateError);
  });

  test('renderGlyph is deterministic for the same letter (stable deckle seed)',
      () async {
    final a = await GlyphAtlas.renderGlyph('ب');
    final b = await GlyphAtlas.renderGlyph('ب');
    expect(a.width, b.width);
    expect(a.height, b.height);
    final dataA = (await a.toByteData())!;
    final dataB = (await b.toByteData())!;
    expect(dataA.buffer.asUint8List(), dataB.buffer.asUint8List());
  });
}
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart 2>&1 | tail -50
```

  Expected: compile errors / failures — `cardSizeFor` doesn't exist, the
  composite image isn't square yet, and no `AlaifCard.color` pixels are
  present.

- [ ] Implement the minimal fix. Replace the entire contents of
      `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart` with:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to composite paper-card
/// textures at load.
///
/// Ink & Paper, device review 1 (decision 3): each letter is baked onto a
/// square "carrier card" — a deckled-edge warm-paper rounded rect with a
/// baked soft shadow and hairline border — with the glyph (Katibeh, two-pass
/// shadow + vertical ink gradient) centered on top. The composite texture is
/// square; its side is the card side, exposed via [cardSizeFor]. Hit circle
/// and cut geometry are derived from this known square geometry by
/// [LetterComponent] and [SlicedHalf] — no pixel scanning.
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

  /// The square carrier card's side length, in texture pixels — equal to
  /// both `imageFor(letter).width` and `imageFor(letter).height`.
  double cardSizeFor(String letter) => imageFor(letter).width.toDouble();

  Future<void> load({
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
    if (_images.isNotEmpty) return; // idempotent — images are native resources
    for (final letter in letters) {
      _images[letter] =
          await renderGlyph(letter, fontSize: fontSize, fontFamily: fontFamily);
    }
  }

  /// Renders [letter] as a composite paper-card texture: deckled card (with
  /// baked shadow + hairline border) first, then the two-pass glyph
  /// (shadow + ink gradient) centered on top. The result is square.
  static Future<ui.Image> renderGlyph(
    String letter, {
    double fontSize = AlaifGlyph.renderFontSize,
    String fontFamily = AlaifFonts.arabic,
  }) async {
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
    final glyphWidth = math.max(measure.width, 1);

    // The bare glyph "box" (glyph + texture padding on all sides), as in the
    // pre-card atlas. The card is this box's longest edge, scaled up.
    final glyphBoxWidth = glyphWidth + pad * 2;
    final glyphBoxHeight = glyphHeight + pad * 2;
    final glyphMaxExtent = math.max(glyphBoxWidth, glyphBoxHeight);

    // Card side, rounded up to a whole pixel so the texture has no
    // fractional-pixel edge.
    final cardSide = (glyphMaxExtent * AlaifCard.paddingFactor).ceil().toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // --- Carrier card ---------------------------------------------------
    final cardPath = _cardPath(letter, cardSide);

    // Baked shadow under the card.
    canvas.drawPath(
      cardPath.shift(const Offset(0, AlaifCard.shadowOffsetY)),
      Paint()
        ..color = AlaifCard.shadowColor
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, AlaifCard.shadowBlur),
    );

    // Paper fill.
    canvas.drawPath(cardPath, Paint()..color = AlaifCard.color);

    // Hairline edge.
    canvas.drawPath(
      cardPath,
      Paint()
        ..color = AlaifCard.edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // --- Glyph, centered on the card -------------------------------------
    final glyphOriginX = (cardSide - glyphWidth) / 2;
    final glyphOriginY = (cardSide - glyphHeight) / 2;

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
      Offset(glyphOriginX, glyphOriginY + AlaifGlyph.shadowOffsetY),
    );

    // Pass 2 — the ink glyph with its vertical gradient.
    final foreground = Paint()
      ..shader = AlaifGradients.glyph.createShader(
        Rect.fromLTWH(glyphOriginX, glyphOriginY, glyphWidth, glyphHeight),
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
    painter.paint(canvas, Offset(glyphOriginX, glyphOriginY));

    final side = math.max(1, cardSide.ceil());
    return recorder.endRecording().toImage(side, side);
  }

  /// Builds the deckled-edge rounded-rect `Path` for a card of side
  /// [cardSide], seeded deterministically from [letter]'s position in
  /// [letters] so the wobble is stable across loads (and identical renders
  /// of the same letter produce byte-identical images).
  static ui.Path _cardPath(String letter, double cardSide) {
    final seed = letters.indexOf(letter);
    final random = math.Random(seed >= 0 ? seed : letter.hashCode);

    const segments = AlaifCard.deckleSegmentsPerEdge;
    const amplitude = AlaifCard.deckleAmplitude;
    const radius = AlaifCard.cornerRadius;

    // Base rounded rect, inset so the deckle wobble never exceeds the
    // texture bounds.
    final base = Rect.fromLTWH(
      amplitude,
      amplitude,
      cardSide - amplitude * 2,
      cardSide - amplitude * 2,
    );

    final path = ui.Path();

    // Walk each edge in `segments` steps, perturbing each interior vertex
    // perpendicular to the edge by a random amount in [-amplitude, amplitude].
    // Corners (the rounded-rect corners) are left unperturbed so the
    // rounding reads cleanly.
    final corners = [
      base.topLeft + Offset(radius, 0),
      base.topRight + Offset(-radius, 0),
      base.topRight + Offset(0, radius),
      base.bottomRight + Offset(0, -radius),
      base.bottomRight + Offset(-radius, 0),
      base.bottomLeft + Offset(radius, 0),
      base.bottomLeft + Offset(0, -radius),
      base.topLeft + Offset(0, radius),
    ];

    void deckledEdge(Offset from, Offset to) {
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      if (length == 0) {
        path.lineTo(to.dx, to.dy);
        return;
      }
      // Unit normal (perpendicular to the edge).
      final nx = -dy / length;
      final ny = dx / length;
      for (var i = 1; i < segments; i++) {
        final t = i / segments;
        final px = from.dx + dx * t;
        final py = from.dy + dy * t;
        final wobble = (random.nextDouble() * 2 - 1) * amplitude;
        path.lineTo(px + nx * wobble, py + ny * wobble);
      }
      path.lineTo(to.dx, to.dy);
    }

    // Start at the first corner, draw deckled edges between corner pairs,
    // and arc around each rounded corner.
    path.moveTo(corners[0].dx, corners[0].dy);
    deckledEdge(corners[0], corners[1]);
    path.arcToPoint(corners[2], radius: const Radius.circular(radius));
    deckledEdge(corners[2], corners[3]);
    path.arcToPoint(corners[4], radius: const Radius.circular(radius));
    deckledEdge(corners[4], corners[5]);
    path.arcToPoint(corners[6], radius: const Radius.circular(radius));
    deckledEdge(corners[6], corners[7]);
    path.arcToPoint(corners[0], radius: const Radius.circular(radius));
    path.close();

    return path;
  }
}
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart 2>&1 | tail -50
```

  Expected: all tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`. Note: `test/game/components_test.dart` and
  `test/game/alaif_game_test.dart` use `testImage()`, a synthetic
  in-test-only image, not `GlyphAtlas.renderGlyph` — they are unaffected by
  this task.

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/core/glyph_atlas.dart test/core/glyph_atlas_test.dart && git commit -m "feat: bake each glyph onto a deckled paper carrier card in GlyphAtlas"
```

---

## Task 8: Card-based hit circle + per-spawn rotation on `LetterComponent`

`LetterComponent.hitRadius` now derives from the component's on-screen size
(== the square carrier card scaled to `targetSize`) via
`AlaifCard.hitRadiusFactor`, instead of the old `size.x / 2`. Each spawned
letter also gets a small random rotation (`±0.12` rad) applied once at
construction, via an injectable `Random` (matching the existing
`Spawner`/`AlaifGame` pattern), so cards feel tossed rather than perfectly
axis-aligned.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/components_test.dart`

### Steps

- [ ] Write failing tests. Open
      `/Users/iammoo/code/alaif/app/test/game/components_test.dart`. The
      current relevant tests are:

```dart
  test('letter hit radius derives from its scaled on-screen size', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
    );
    expect(letter.hitRadius, 40);
  });

  test('letter scales its texture down to targetSize, keeping aspect', () async {
    final image = await testImage(width: 100, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100,
    );
    expect(letter.size, Vector2(50, 100)); // longest edge == targetSize
    expect(letter.hitRadius, 25);
  });
```

  Replace these two tests with the following (updated `hitRadius`
  expectations using `AlaifCard.hitRadiusFactor`, plus new tests for
  rotation):

```dart
  test('letter hit radius derives from its scaled on-screen size via AlaifCard.hitRadiusFactor', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
    );
    // size is (80, 80); hitRadius = max(size.x, size.y) / 2 * hitRadiusFactor.
    expect(letter.hitRadius, 80 / 2 * AlaifCard.hitRadiusFactor);
  });

  test('letter scales its texture down to targetSize, keeping aspect, and hitRadius follows', () async {
    final image = await testImage(width: 100, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 100,
    );
    expect(letter.size, Vector2(50, 100)); // longest edge == targetSize
    // hitRadius = max(size.x, size.y) / 2 * hitRadiusFactor = max(50,100)/2 * factor.
    expect(letter.hitRadius, 100 / 2 * AlaifCard.hitRadiusFactor);
  });

  test('letter with no random source gets zero extra rotation', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
    );
    expect(letter.angle, 0);
  });

  test('letter with a seeded random source gets a small fixed rotation in [-0.12, 0.12] rad', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
      random: Random(42),
    );
    expect(letter.angle, greaterThanOrEqualTo(-0.12));
    expect(letter.angle, lessThanOrEqualTo(0.12));
    // Same seed -> same rotation (deterministic).
    final again = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
      targetSize: 80,
      random: Random(42),
    );
    expect(again.angle, letter.angle);
  });
```

  Add the `dart:math` import for `Random` at the top of the file. The current
  top of the file is:

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
```

  Change it to:

```dart
import 'dart:math';
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
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -50
```

  Expected: failures — `hitRadius` still equals the old `size.x / 2` values
  (40 and 25), and `LetterComponent` has no `random` constructor parameter
  (compile error for the rotation tests).

- [ ] Implement the minimal fix. Replace the entire contents of
      `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart` with:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

/// Maximum magnitude of the per-spawn random "toss" rotation (radians),
/// applied once at construction when a [Random] source is supplied.
const double _maxSpawnRotation = 0.12;

class LetterComponent extends PositionComponent {
  LetterComponent({
    required this.letter,
    required ui.Image image,
    required this.motion,
    double targetSize = AlaifGlyph.spawnSizeMax,
    math.Random? random,
  }) : _image = image {
    final longest = math.max(image.width, image.height).toDouble();
    final scale = targetSize / longest;
    size = Vector2(image.width * scale, image.height * scale);
    anchor = Anchor.center;
    position = motion.positionAt(0);

    // Hit circle is the inscribed circle of the (square) carrier card,
    // scaled slightly by AlaifCard.hitRadiusFactor for a forgiving hit area.
    // For non-square textures (e.g. test fixtures), use the longer scaled
    // edge so the hit area still comfortably covers the texture.
    _hitRadius = math.max(size.x, size.y) / 2 * AlaifCard.hitRadiusFactor;

    // Per-spawn "toss": a small fixed rotation in [-0.12, 0.12] rad, applied
    // once. Omitted (angle stays 0) when no Random source is supplied, so
    // existing callers that don't care about rotation are unaffected.
    if (random != null) {
      angle = (random.nextDouble() * 2 - 1) * _maxSpawnRotation;
    }
  }

  final String letter;
  final ArcMotion motion;
  final ui.Image _image;
  double _age = 0;
  late final double _hitRadius;

  /// Set once the letter has been on screen; used for missed-letter detection.
  bool entered = false;

  /// Set the instant this letter is sliced, before `removeFromParent()` takes
  /// effect (which Flame defers to the next update tick). Prevents a single
  /// swipe's later drag-update segments from re-slicing the same letter.
  bool sliced = false;

  ui.Image get image => _image;

  /// Circular hit approximation centered on the component, sized from the
  /// scaled carrier-card geometry (see [AlaifCard.hitRadiusFactor]).
  double get hitRadius => _hitRadius;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
    angle += 0.5 * dt; // gentle tumble (in addition to the fixed spawn tilt)
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
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -50
```

  Expected: all tests in this file pass.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/letter_component.dart test/game/components_test.dart && git commit -m "feat: derive LetterComponent hit circle from card geometry and add spawn-toss rotation"
```

---

## Task 9: Swipe-angle half-plane cut + impulse on `SlicedHalf`

`SlicedHalf` clips the composite card texture with a half-plane `Path`
through the card center along the swipe direction (degenerate/zero-length
swipe falls back to a horizontal cut). The two halves separate perpendicular
to the cut line with an impulse scaled by swipe speed (clamped), on top of
the existing gravity/tumble. `trySlice` threads the swipe segment through to
`_sliceLetter`, which computes the cut direction and impulse and spawns the
ink burst at the letter center.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/components_test.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`

### Steps

- [ ] Write failing tests for `SlicedHalf`. Open
      `/Users/iammoo/code/alaif/app/test/game/components_test.dart` and add
      the following inside `void main() { ... }`, after the `LetterComponent`
      tests added in Task 8 (placement among tests does not matter, only that
      they are inside `main()`):

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

    test('vertical cut through center: positive side keeps the left half', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2(0, 1), // vertical line x=50
        keepPositiveSide: true, // normal = (-1,0) -> positive side is x < 50
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

    test('zero-length cut direction falls back to horizontal', () {
      final path = SlicedHalf.halfPlanePath(
        size: Vector2(100, 100),
        cutCenter: Vector2(50, 50),
        cutDirection: Vector2.zero(),
        keepPositiveSide: true,
      );
      expect(path.contains(const ui.Offset(50, 90)), isTrue); // below
      expect(path.contains(const ui.Offset(50, 10)), isFalse); // above
    });
  });

  testWithGame<AlaifGame>('sliced half defaults to a horizontal cut through its center',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage(width: 100, height: 100);
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000,
      displaySize: Vector2(100, 100),
    );
    expect(half.cutCenter, Vector2(50, 50));
    expect(half.cutDirection, Vector2(1, 0));

    final recorder = ui.PictureRecorder();
    half.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });

  testWithGame<AlaifGame>('sliced half with explicit cut geometry renders without throwing',
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
      cutDirection: Vector2(1, 1),
    );
    await game.add(half);
    game.update(0);

    final recorder = ui.PictureRecorder();
    half.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
```

  Add the `cutCenter`/`cutDirection` getters and `halfPlanePath` static
  method don't exist yet — confirmed by the next step.

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart 2>&1 | tail -50
```

  Expected: compile errors — `SlicedHalf.halfPlanePath`, `cutCenter`, and
  `cutDirection` don't exist, and the constructor has no
  `cutCenter`/`cutDirection` parameters.

- [ ] Implement the half-plane clip in `SlicedHalf`. Replace the entire
      contents of `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart`
      with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';

/// One half of a sliced glyph card, clipped from the full composite texture
/// along the swipe's cut line, tumbling away.
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
    // a plain top/bottom split when no swipe geometry is given.
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

  /// Current tumble velocity (px/s). Exposed for testing the perpendicular
  /// separation of the two halves.
  Vector2 get velocity => _velocity;

  /// Point (in local component coordinates) the cut line passes through.
  Vector2 get cutCenter => _cutCenter;

  /// Unit vector along the cut line that produced this half.
  Vector2 get cutDirection => _cutDirection;

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
  /// normalized; will be normalized internally — a zero-length direction
  /// falls back to horizontal, i.e. `(1, 0)`).
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

  Expected: all tests in this file pass, including the new
  `SlicedHalf.halfPlanePath` group and the two new `SlicedHalf` rendering
  tests. The pre-existing tests `'sliced half is removed after
  cutHalfTumbleMs'` and `'sliced half falls and removes itself below the
  cutoff'` construct `SlicedHalf` without `cutCenter`/`cutDirection` — these
  must still pass via the defaults.

- [ ] Add the swipe-impulse tunables to `AlaifMotion`. Open
      `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`. The current
      `AlaifMotion` class is:

```dart
abstract class AlaifMotion {
  // Blade trail (BladeTrail component).
  static const bladeRetentionMs = 110; // how long a trail point lives
  static const bladeWidth = 7.0; // head thickness
  static const bladeMinWidth = 1.5; // tail thickness (tapers to this)

  // Cut feedback — ink splatter when a letter is sliced.
  static const cutInkParticles = 14;
  static const cutParticleSpeedMin = 120.0; // px/s
  static const cutParticleSpeedMax = 360.0;
  static const cutParticleLifeMs = 520;
  static const cutHalfTumbleMs = 900; // sliced halves spin off-screen

  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade

  // Score / life pops.
  static const scorePopMs = 220;
  static const lifeLostFlashMs = 280;

  // Standard overlay transition.
  static const overlayFadeMs = 220;
  static const overlayCurve = Curves.easeOutCubic;
}
```

  Change it to:

```dart
abstract class AlaifMotion {
  // Blade trail (BladeTrail component).
  static const bladeRetentionMs = 110; // how long a trail point lives
  static const bladeWidth = 7.0; // head thickness
  static const bladeMinWidth = 1.5; // tail thickness (tapers to this)

  // Cut feedback — ink splatter when a letter is sliced.
  static const cutInkParticles = 14;
  static const cutParticleSpeedMin = 120.0; // px/s
  static const cutParticleSpeedMax = 360.0;
  static const cutParticleLifeMs = 520;
  static const cutHalfTumbleMs = 900; // sliced halves spin off-screen

  // Sliced-half separation impulse, perpendicular to the cut line.
  static const cutSeparationBaseSpeed = 150.0; // px/s, floor (slow swipes)
  static const cutSeparationSwipeScale = 1.5; // extra px/s per px of swipe segment
  static const cutSeparationMaxSpeed = 900.0; // px/s, ceiling (fast swipes)

  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade

  // Score / life pops.
  static const scorePopMs = 220;
  static const lifeLostFlashMs = 280;

  // Standard overlay transition.
  static const overlayFadeMs = 220;
  static const overlayCurve = Curves.easeOutCubic;
}
```

- [ ] Write failing tests for the swipe-angle threading. Open
      `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`. Add the
      following inside `void main() { ... }`, after the `'a letter already
      sliced this frame is not sliced again by a later segment'` test added
      in Task 1:

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
      // Cut passes through the letter's center.
      expect(half.cutCenter, letter.size / 2);
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

  testWithGame<AlaifGame>(
      'a fast swipe produces a larger half-separation impulse than a slow one',
      AlaifGame.new, (game) async {
    game.startGame();

    final slowLetter = staticLetter(game, x: 100, y: 300);
    game.add(slowLetter);
    game.update(0);
    game.trySlice(Vector2(99, 300), Vector2(101, 300)); // tiny 2px segment
    game.update(0);
    final slowHalves = game.children.whereType<SlicedHalf>().toList();
    final slowSpeed = slowHalves.first.velocity.length;

    game.startGame(); // clears halves and resets state

    final fastLetter = staticLetter(game, x: 100, y: 300);
    game.add(fastLetter);
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(800, 300)); // large fast segment
    game.update(0);
    final fastHalves = game.children.whereType<SlicedHalf>().toList();
    final fastSpeed = fastHalves.first.velocity.length;

    expect(fastSpeed, greaterThan(slowSpeed));
    // Even the fast swipe is clamped.
    // velocity = perp * separationSpeed + popVelocity (0, -100), so its
    // magnitude is bounded by the clamped separation speed plus the pop
    // velocity's length.
    const popVelocityLength = 100.0; // matches AlaifGame's _halfPopVelocity
    expect(
      fastSpeed,
      lessThanOrEqualTo(AlaifMotion.cutSeparationMaxSpeed + popVelocityLength),
    );
  });
```

  Add the imports needed for these tests. The current top of
  `alaif_game_test.dart` is:

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/audio_service.dart';
import 'package:alaif/services/haptics_service.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

  Add `package:alaif/ui/design_tokens.dart` (for `AlaifMotion`):

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/audio_service.dart';
import 'package:alaif/services/haptics_service.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -60
```

  Expected: compile error / failure — `_sliceLetter` is still called with one
  argument and does not vary the cut by swipe direction, so `cutCenter`/
  `cutDirection`/`velocity` differences don't yet match the new tests.

- [ ] Implement the cut-geometry threading in `AlaifGame`. Open
      `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. The current
      `trySlice` letter loop (after Task 1) is:

```dart
  void trySlice(Vector2 from, Vector2 to) {
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter);
      }
    }
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        audio.playBomb();
        _checkGameOver();
      }
    }
  }
```

  Change the letter loop's `_sliceLetter` call to pass the swipe segment:

```dart
  void trySlice(Vector2 from, Vector2 to) {
    if (!_playing) return;
    for (final letter in children.whereType<LetterComponent>().toList()) {
      if (letter.sliced) continue;
      if (segmentHitsCircle(from, to, letter.position, letter.hitRadius)) {
        _sliceLetter(letter, from, to);
      }
    }
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        audio.playBomb();
        _checkGameOver();
      }
    }
  }
```

  Then replace the entire `_sliceLetter` method — currently (after Task 1):

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

  Replace it with:

```dart
  /// Shared upward "pop" velocity (px/s) added to both halves' separation.
  static final Vector2 _halfPopVelocity = Vector2(0, -100);

  void _sliceLetter(LetterComponent letter, Vector2 swipeFrom, Vector2 swipeTo) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
    _lastSlicePosition = letter.position.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(letter.position, _random),
    ));

    // Cut direction follows the swipe; degenerate (zero-length) segments
    // fall back to a horizontal cut. The cut always passes through the
    // card's center (the component's local center, size / 2).
    final swipeVector = swipeTo - swipeFrom;
    final cutDirection = swipeVector.length2 > 0
        ? (swipeVector.clone()..normalize())
        : Vector2(1, 0);
    final cutCenter = letter.size / 2;

    // Halves separate perpendicular to the cut line, with an impulse scaled
    // by the swipe segment's length (a proxy for swipe speed), clamped, plus
    // a shared upward pop.
    final perp = Vector2(-cutDirection.y, cutDirection.x);
    final separationSpeed = (AlaifMotion.cutSeparationBaseSpeed +
            swipeVector.length * AlaifMotion.cutSeparationSwipeScale)
        .clamp(AlaifMotion.cutSeparationBaseSpeed, AlaifMotion.cutSeparationMaxSpeed);

    final cutoff = size.y + 200;
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: perp * separationSpeed + _halfPopVelocity,
      topHalf: true,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
      cutCenter: cutCenter,
      cutDirection: cutDirection,
    ));
    add(SlicedHalf(
      image: letter.image,
      startPosition: letter.position,
      velocity: -perp * separationSpeed + _halfPopVelocity,
      topHalf: false,
      removeBelowY: cutoff,
      displaySize: letter.size.clone(),
      cutCenter: cutCenter,
      cutDirection: cutDirection,
    ));
  }
```

- [ ] Run the targeted tests again and confirm they pass:

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
cd /Users/iammoo/code/alaif/app && git add lib/game/alaif_game.dart lib/game/sliced_halves.dart lib/ui/design_tokens.dart test/game/alaif_game_test.dart test/game/components_test.dart && git commit -m "feat: cut letter cards along the swipe direction with a speed-scaled separation impulse"
```

---

## Task 10: Hit-stop juice on slice

On each successful slice, `AlaifGame` sets a short hit-stop timer
(`AlaifMotion.hitStopMs`, ~50ms). While the timer is active, `update()`
scales the simulation `dt` passed to `super.update()` down to
`AlaifMotion.hitStopScale` (~0.05) — components barely move for a brief
moment, landing the cut with impact. The hit-stop timer itself counts down
using the **real**, unscaled `dt` so it cannot lock up. Pause/overlay logic
is unaffected (hit-stop only scales the gameplay-simulation `dt` inside
`update()`, and `update()` already early-returns from its `_playing`-gated
block regardless).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`
- Modify: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`

### Steps

- [ ] Add the hit-stop tunables to `AlaifMotion`. Open
      `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart`. The current
      `AlaifMotion` class (after Task 9) is:

```dart
abstract class AlaifMotion {
  // Blade trail (BladeTrail component).
  static const bladeRetentionMs = 110; // how long a trail point lives
  static const bladeWidth = 7.0; // head thickness
  static const bladeMinWidth = 1.5; // tail thickness (tapers to this)

  // Cut feedback — ink splatter when a letter is sliced.
  static const cutInkParticles = 14;
  static const cutParticleSpeedMin = 120.0; // px/s
  static const cutParticleSpeedMax = 360.0;
  static const cutParticleLifeMs = 520;
  static const cutHalfTumbleMs = 900; // sliced halves spin off-screen

  // Sliced-half separation impulse, perpendicular to the cut line.
  static const cutSeparationBaseSpeed = 150.0; // px/s, floor (slow swipes)
  static const cutSeparationSwipeScale = 1.5; // extra px/s per px of swipe segment
  static const cutSeparationMaxSpeed = 900.0; // px/s, ceiling (fast swipes)

  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade

  // Score / life pops.
  static const scorePopMs = 220;
  static const lifeLostFlashMs = 280;

  // Standard overlay transition.
  static const overlayFadeMs = 220;
  static const overlayCurve = Curves.easeOutCubic;
}
```

  Change it to:

```dart
abstract class AlaifMotion {
  // Blade trail (BladeTrail component).
  static const bladeRetentionMs = 110; // how long a trail point lives
  static const bladeWidth = 7.0; // head thickness
  static const bladeMinWidth = 1.5; // tail thickness (tapers to this)

  // Cut feedback — ink splatter when a letter is sliced.
  static const cutInkParticles = 14;
  static const cutParticleSpeedMin = 120.0; // px/s
  static const cutParticleSpeedMax = 360.0;
  static const cutParticleLifeMs = 520;
  static const cutHalfTumbleMs = 900; // sliced halves spin off-screen

  // Sliced-half separation impulse, perpendicular to the cut line.
  static const cutSeparationBaseSpeed = 150.0; // px/s, floor (slow swipes)
  static const cutSeparationSwipeScale = 1.5; // extra px/s per px of swipe segment
  static const cutSeparationMaxSpeed = 900.0; // px/s, ceiling (fast swipes)

  // Hit-stop — brief simulation slowdown on a successful slice, for impact.
  static const hitStopMs = 50; // real-time duration of the slowdown
  static const hitStopScale = 0.05; // dt multiplier while hit-stop is active

  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade

  // Score / life pops.
  static const scorePopMs = 220;
  static const lifeLostFlashMs = 280;

  // Standard overlay transition.
  static const overlayFadeMs = 220;
  static const overlayCurve = Curves.easeOutCubic;
}
```

- [ ] Write failing tests. Open
      `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` and add
      the following inside `void main() { ... }`, after the swipe-impulse
      tests added in Task 9:

```dart
  testWithGame<AlaifGame>(
      'slicing a letter triggers a brief hit-stop that scales down dt for the simulation',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = staticLetter(game, x: 100, y: 300);
    game.add(letter);
    game.update(0); // mount

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0); // process slice

    final half = game.children.whereType<SlicedHalf>().first;
    final yBefore = half.position.y;

    // During hit-stop, a real-time-sized dt should barely move the half.
    final hitStopDt = AlaifMotion.hitStopMs / 1000;
    game.update(hitStopDt);
    final yDuringHitStop = half.position.y;
    expect(yDuringHitStop - yBefore, lessThan(1.0));

    // After the hit-stop window elapses, the same dt advances normally.
    game.update(hitStopDt);
    final yAfterHitStop = half.position.y;
    expect(yAfterHitStop - yDuringHitStop, greaterThan(1.0));
  });

  testWithGame<AlaifGame>('hit-stop does not affect the game when no slice has occurred',
      AlaifGame.new, (game) async {
    game.startGame();
    final letter = LetterComponent(
      letter: 'ب',
      image: game.atlas.imageFor('ب'),
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2(0, 100), gravity: 0),
    );
    game.add(letter);
    game.update(0); // mount

    final yBefore = letter.position.y;
    game.update(0.1);
    expect(letter.position.y - yBefore, closeTo(10, 1e-9)); // unscaled dt
  });
```

  `LetterComponent` is already imported via
  `package:alaif/game/letter_component.dart` and `ArcMotion` via
  `package:alaif/core/arc_motion.dart` (both already present in this file's
  imports — check the current import list and add only if missing).

- [ ] Run it and confirm it fails:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -50
```

  Expected: the first new test fails — `update()` does not yet scale `dt`
  during a hit-stop window, so `yDuringHitStop - yBefore` is not `< 1.0`. The
  second new test should already pass (it doesn't depend on the new
  behavior) — that's fine, it documents the no-hit-stop baseline.

- [ ] Implement the minimal fix. Open
      `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. The current
      `update` method is:

```dart
  @override
  void update(double dt) {
    // Check positions before super.update so that externally-mutated positions
    // (e.g. in tests) are visible before child update() resets them via ArcMotion.
    if (_playing) {
      for (final letter in children.whereType<LetterComponent>().toList()) {
        if (!letter.entered && letter.position.y < size.y) letter.entered = true;
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
          audio.playMiss();
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
    super.update(dt);
  }
```

  Change it to:

```dart
  @override
  void update(double dt) {
    // Check positions before super.update so that externally-mutated positions
    // (e.g. in tests) are visible before child update() resets them via ArcMotion.
    if (_playing) {
      for (final letter in children.whereType<LetterComponent>().toList()) {
        if (!letter.entered && letter.position.y < size.y) letter.entered = true;
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
          audio.playMiss();
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

    // Hit-stop: a brief slowdown of the simulation on a successful slice, for
    // impact. The countdown itself uses the real (unscaled) dt so it always
    // recovers, even at very low frame rates.
    if (_hitStopRemainingMs > 0) {
      _hitStopRemainingMs -= dt * 1000;
      super.update(dt * AlaifMotion.hitStopScale);
      return;
    }
    super.update(dt);
  }
```

  Then add the hit-stop field. The current field declarations near the top of
  the class are:

```dart
  String _settingsReturnOverlay = 'menu';
  final Random _random;
  Vector2? _lastSlicePosition;
```

  Change them to:

```dart
  String _settingsReturnOverlay = 'menu';
  final Random _random;
  Vector2? _lastSlicePosition;

  /// Remaining real-time milliseconds of the current hit-stop. While > 0,
  /// [update] scales the simulation `dt` by [AlaifMotion.hitStopScale].
  double _hitStopRemainingMs = 0;
```

  Finally, trigger the hit-stop on slice. In `_sliceLetter` (after Task 9),
  the method starts:

```dart
  void _sliceLetter(LetterComponent letter, Vector2 swipeFrom, Vector2 swipeTo) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
```

  Change it to:

```dart
  void _sliceLetter(LetterComponent letter, Vector2 swipeFrom, Vector2 swipeTo) {
    letter.sliced = true;
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    _hitStopRemainingMs = AlaifMotion.hitStopMs.toDouble();
    letter.removeFromParent();
```

- [ ] Run the targeted test again and confirm it passes:

```
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart 2>&1 | tail -50
```

  Expected: all tests in this file pass, including both new hit-stop tests.

- [ ] Run the full suite and confirm it is green:

```
cd /Users/iammoo/code/alaif/app && flutter test 2>&1 | tail -20
```

  Expected: `All tests passed!`

- [ ] Commit:

```
cd /Users/iammoo/code/alaif/app && git add lib/game/alaif_game.dart lib/ui/design_tokens.dart test/game/alaif_game_test.dart && git commit -m "feat: brief hit-stop on slice for impact juice"
```

---

## Task 11: Final verification — analyze + full suite

No code changes. Confirms the whole branch is clean: static analysis passes
and every test (110 original + new ones from Tasks 1-10) is green.

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

- [ ] If either command reports any issue, fix it in the relevant file from
      Tasks 1-10 (do not introduce new features), re-run both commands, and
      only proceed once both are clean.

- [ ] No commit for this task unless a fix was needed in the previous step —
      if a fix was needed, commit it with:

```
cd /Users/iammoo/code/alaif/app && git add -A && git commit -m "fix: address flutter analyze / test issues from device review 1 fixes"
```
