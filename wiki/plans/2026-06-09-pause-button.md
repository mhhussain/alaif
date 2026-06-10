# Pause Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox syntax.

**Goal:** Add a persistent on-screen pause button to the Alaif game so players can pause mid-run via a UI control (in addition to the existing app-lifecycle auto-pause).
**Architecture:** A new lightweight Flutter overlay (`'controls'`) is added by `AlaifGame.startGame()` and removed by `_checkGameOver()`, mirroring how `'menu'`/`'gameOver'`/`'paused'` are managed. The overlay is a top-right `IconButton` (pause icon) wrapped in `Align` + `SafeArea` so taps elsewhere fall through to the `GameWidget`. While the `'paused'` overlay is showing, `'controls'` is hidden (removed in `pauseGame()`, re-added in `resumeFromPause()`) to avoid a double-pause control stack. The button calls `game.pauseGame()`, which already shows `'paused'`.
**Tech Stack:** Flutter, Flame (`flame`, `flame_test`), `flutter_test`, existing overlay pattern (`StatelessWidget` overlays keyed by string in `overlayBuilderMap` + `FlameGame.overlays`).

---

## Task 1: Create the `controls` overlay widget + widget test

- [ ] Create `/Users/iammoo/code/alaif/app/test/ui/controls_overlay_test.dart` with the following content:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/controls_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('controls overlay shows a pause icon button', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('controls overlay is positioned top-right via Align',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    final align = tester.widget<Align>(find.byType(Align));
    expect(align.alignment, Alignment.topRight);
  });

  testWidgets('tapping the pause button calls game.pauseGame and shows paused overlay',
      (tester) async {
    final game = AlaifGame();
    await tester.pumpWidget(GameWidget<AlaifGame>(
      game: game,
      overlayBuilderMap: {
        'controls': (context, game) => ControlsOverlay(game: game),
      },
      initialActiveOverlays: const ['controls'],
    ));
    await tester.pump();
    await tester.pump();

    game.startGame();
    await tester.pump();

    expect(game.isPlaying, isTrue);
    expect(game.paused, isFalse);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(game.paused, isTrue);
    expect(game.overlays.isActive('paused'), isTrue);
  });
}
```

- [ ] Run the test to confirm it fails because `controls_overlay.dart` doesn't exist yet:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/controls_overlay_test.dart
```

  Expected output: a compile error similar to `Error: Couldn't resolve the package 'alaif/ui/controls_overlay.dart'` (or `Target of URI doesn't exist`).

- [ ] Create `/Users/iammoo/code/alaif/app/lib/ui/controls_overlay.dart` with the following content:

```dart
import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.pause, color: Colors.white70, size: 32),
            onPressed: game.pauseGame,
          ),
        ),
      ),
    );
  }
}
```

- [ ] Run the test again and confirm it passes:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/controls_overlay_test.dart
```

  Expected output: `00:0X +3: All tests passed!`

- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif/app && git add lib/ui/controls_overlay.dart test/ui/controls_overlay_test.dart && git commit -m "Add controls overlay with pause button"
```

---

## Task 2: Wire `controls` overlay lifecycle into `AlaifGame`

- [ ] In `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`, add the following test at the end of the `main()` body, immediately before the closing `});` of the last `testWithGame` block's enclosing `main()` (i.e. as a new top-level `testWithGame` call after the `'losing all lives ends the game and shows overlay'` test):

```dart
  testWithGame<AlaifGame>(
      'controls overlay is shown while playing and hidden on game over',
      AlaifGame.new, (game) async {
    expect(game.overlays.isActive('controls'), isFalse);

    game.startGame();
    expect(game.overlays.isActive('controls'), isTrue);

    game.rules.onBombSliced();
    game.rules.onBombSliced();
    game.rules.onBombSliced();
    final letter = staticLetter(game)..entered = true;
    game.add(letter);
    game.update(0);
    letter.position.y = game.size.y + 500;
    game.update(0);

    expect(game.isPlaying, isFalse);
    expect(game.overlays.isActive('gameOver'), isTrue);
    expect(game.overlays.isActive('controls'), isFalse);
  });

  testWithGame<AlaifGame>(
      'pausing hides controls and resuming restores them',
      AlaifGame.new, (game) async {
    game.startGame();
    expect(game.overlays.isActive('controls'), isTrue);

    game.pauseGame();
    expect(game.overlays.isActive('paused'), isTrue);
    expect(game.overlays.isActive('controls'), isFalse);

    game.resumeFromPause();
    expect(game.overlays.isActive('paused'), isFalse);
    expect(game.overlays.isActive('controls'), isTrue);
  });
```

- [ ] Run the new tests to confirm they fail (the `'controls'` overlay is never added/removed yet):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart
```

  Expected output: 2 new failures, e.g. `Expected: true / Actual: <false>` on `expect(game.overlays.isActive('controls'), isTrue)`.

- [ ] In `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`, update the guarded stub-registration list in `onLoad()` from:

```dart
    for (final name in const ['menu', 'gameOver', 'paused']) {
```

  to:

```dart
    for (final name in const ['menu', 'gameOver', 'paused', 'controls']) {
```

- [ ] In the same file, update `startGame()`. Change:

```dart
    if (paused) resumeEngine(); // close the pause-then-restart gap
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
    overlays.remove('paused');
  }
```

  to:

```dart
    if (paused) resumeEngine(); // close the pause-then-restart gap
    _playing = true;
    overlays.remove('menu');
    overlays.remove('gameOver');
    overlays.remove('paused');
    overlays.add('controls');
  }
```

- [ ] Update `_checkGameOver()`. Change:

```dart
  void _checkGameOver() {
    if (!rules.isGameOver || !_playing) return;
    _playing = false;
    unawaited(highScores.submit(scoreState.score)); // fire-and-forget by design
    overlays.add('gameOver');
  }
```

  to:

```dart
  void _checkGameOver() {
    if (!rules.isGameOver || !_playing) return;
    _playing = false;
    unawaited(highScores.submit(scoreState.score)); // fire-and-forget by design
    overlays.remove('controls');
    overlays.add('gameOver');
  }
```

- [ ] Update `pauseGame()` and `resumeFromPause()`. Change:

```dart
  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    overlays.add('paused');
  }

  void resumeFromPause() {
    overlays.remove('paused');
    resumeEngine();
  }
```

  to:

```dart
  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    overlays.remove('controls');
    overlays.add('paused');
  }

  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
  }
```

- [ ] Run the full game test suite to confirm everything passes:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart
```

  Expected output: `00:0X +7: All tests passed!` (5 original + 2 new).

- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif/app && git add lib/game/alaif_game.dart test/game/alaif_game_test.dart && git commit -m "Show/hide controls overlay across play, pause, and game-over transitions"
```

---

## Task 3: Register `controls` overlay in `main.dart` and run full suite

- [ ] In `/Users/iammoo/code/alaif/app/lib/main.dart`, add the import for `ControlsOverlay`. Change:

```dart
import 'game/alaif_game.dart';
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
```

  to:

```dart
import 'game/alaif_game.dart';
import 'ui/controls_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
```

- [ ] In the same file, add the `'controls'` entry to `overlayBuilderMap`. Change:

```dart
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
            },
```

  to:

```dart
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
              'controls': (context, game) => ControlsOverlay(game: game),
            },
```

- [ ] Run the full test suite to confirm no regressions:

```bash
cd /Users/iammoo/code/alaif/app && flutter test
```

  Expected output: `00:0X +54: All tests passed!` (49 original + 3 from `controls_overlay_test.dart` + 2 new in `alaif_game_test.dart` = 54).

- [ ] Run `flutter analyze` to confirm no lint issues:

```bash
cd /Users/iammoo/code/alaif/app && flutter analyze
```

  Expected output: `No issues found!`

- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif/app && git add lib/main.dart && git commit -m "Register controls overlay in GameWidget overlay builder map"
```
</content>
