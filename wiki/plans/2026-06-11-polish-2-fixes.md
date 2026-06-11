# Audio/Haptics/Bomb FX/Topbar Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up the looping background music track, enable Android haptic feedback, give bombs a visual "ink splat" effect on slice, and fix the pause button overlapping the HUD's lives dots.

**Architecture:** Each task is independent and touches a small, focused set of files: `AudioService` gains background-music methods wired into `AlaifGame`'s lifecycle; an Android manifest permission unblocks already-implemented haptics; `ink_particles.dart` gains a bomb-specific particle burst spawned from `AlaifGame.trySlice`; `ControlsOverlay` gets repositioned padding.

**Tech Stack:** Flutter, Flame game engine, `flame_audio` (`FlameAudio.bgm`), `flutter_test` / `flame_test`.

**Branch:** `fix/polish-2` off `main`.

---

## Setup

- [ ] **Step 0: Create the branch**

```bash
git checkout -b fix/polish-2
```

All work in this plan happens in `/Users/iammoo/code/alaif/app`. Run all `flutter`/`dart` commands from that directory.

---

### Task 1: Background music loop

**Files:**
- Modify: `app/lib/services/audio_service.dart`
- Modify: `app/lib/game/alaif_game.dart`
- Test: `app/test/services/audio_service_test.dart`
- Test: `app/test/game/alaif_game_test.dart`

This task adds three new public methods to `AudioService` (`playBackgroundMusic`, `pauseBackgroundMusic`, `resumeBackgroundMusic`), each backed by an overridable `*Internal` method (matching the existing `playInternal` pattern so tests can avoid touching `FlameAudio`). Then it wires these into `AlaifGame`: start music in `onLoad`, pause it in `pauseGame()` and when the app is backgrounded, resume it in `resumeFromPause()`.

- [ ] **Step 1: Write failing tests for the new `AudioService` methods**

Open `app/test/services/audio_service_test.dart`. Add a new test double class at the bottom of the file (after the existing `AudioServiceForTest` class):

```dart
/// Test double that bypasses FlameAudio's Bgm entirely and records every
/// background-music call that actually reached playback.
class BgmRecordingAudioService extends AudioService {
  BgmRecordingAudioService({required this.calls});

  final List<String> calls;

  @override
  Future<void> playBackgroundMusicInternal() async => calls.add('play');

  @override
  void pauseBackgroundMusicInternal() => calls.add('pause');

  @override
  void resumeBackgroundMusicInternal() => calls.add('resume');
}
```

Then add these tests inside `main()`, after the existing `playSlice cooldown does not affect other SFX` test (before the closing `}` of `main`):

```dart
  test('background music methods never throw with no audio backend',
      () async {
    final service = AudioService();
    await service.playBackgroundMusic();
    service.pauseBackgroundMusic();
    service.resumeBackgroundMusic();
  });

  test('enabled service forwards to bgm play/pause/resume', () async {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls);

    await service.playBackgroundMusic();
    service.pauseBackgroundMusic();
    service.resumeBackgroundMusic();

    expect(calls, ['play', 'pause', 'resume']);
  });

  test('disabled service skips playBackgroundMusic and resumeBackgroundMusic',
      () async {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls)..enabled = false;

    await service.playBackgroundMusic();
    service.resumeBackgroundMusic();

    expect(calls, isEmpty);
  });

  test('pauseBackgroundMusic runs even when the service is disabled', () {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls)..enabled = false;

    service.pauseBackgroundMusic();

    expect(calls, ['pause']);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
flutter test test/services/audio_service_test.dart
```

Expected: compile errors / failures referencing `playBackgroundMusic`, `pauseBackgroundMusic`, `resumeBackgroundMusic`, `playBackgroundMusicInternal`, `pauseBackgroundMusicInternal`, `resumeBackgroundMusicInternal` — these methods don't exist on `AudioService` yet.

- [ ] **Step 3: Implement the new `AudioService` methods**

In `app/lib/services/audio_service.dart`, add the following constants near the top of the class (after the existing `static const` SFX names, e.g. after `missSfx`):

```dart
  static const backgroundMusic = 'background.mp3';
  static const musicVolume = 0.5;
```

Then add these methods to the class, after `playMiss()`:

```dart
  /// Starts the looping background music track. Safe to call repeatedly;
  /// failures (missing file, no audio backend in tests) are silent.
  Future<void> playBackgroundMusic() async {
    if (!enabled) return;
    await playBackgroundMusicInternal();
  }

  /// Performs the actual bgm playback. Split out so tests can override it
  /// without touching FlameAudio (which has no backend in test environments).
  Future<void> playBackgroundMusicInternal() async {
    try {
      await FlameAudio.bgm.play(backgroundMusic, volume: musicVolume);
    } catch (_) {
      // Missing file or no audio backend: non-fatal.
    }
  }

  void pauseBackgroundMusic() => pauseBackgroundMusicInternal();

  void pauseBackgroundMusicInternal() {
    try {
      FlameAudio.bgm.pause();
    } catch (_) {
      // No audio backend: non-fatal.
    }
  }

  void resumeBackgroundMusic() {
    if (!enabled) return;
    resumeBackgroundMusicInternal();
  }

  void resumeBackgroundMusicInternal() {
    try {
      FlameAudio.bgm.resume();
    } catch (_) {
      // No audio backend: non-fatal.
    }
  }
```

`FlameAudio.bgm` is already available via the existing `import 'package:flame_audio/flame_audio.dart';` at the top of the file — no new imports needed.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/services/audio_service_test.dart
```

Expected: all tests pass (PASS), including the four new ones.

- [ ] **Step 5: Commit**

```bash
git add lib/services/audio_service.dart test/services/audio_service_test.dart
git commit -m "feat: add background music controls to AudioService"
```

- [ ] **Step 6: Write failing tests for `AlaifGame` wiring**

Open `app/test/game/alaif_game_test.dart`. It currently imports `package:flutter/widgets.dart`? Check the top imports — if `AppLifecycleState` is not imported, add this import alongside the existing `package:alaif/...` imports:

```dart
import 'package:flutter/widgets.dart' show AppLifecycleState;
```

Extend the existing `RecordingAudio` class (used by several tests) to also record background-music calls. Replace:

```dart
class RecordingAudio extends AudioService {
  final events = <String>[];
  @override
  Future<void> preload() async => events.add('preload');
  @override
  void playSlice() => events.add('slice');
  @override
  void playBomb() => events.add('bomb');
  @override
  void playCombo() => events.add('combo');
  @override
  void playMiss() => events.add('miss');
}
```

with:

```dart
class RecordingAudio extends AudioService {
  final events = <String>[];
  @override
  Future<void> preload() async => events.add('preload');
  @override
  void playSlice() => events.add('slice');
  @override
  void playBomb() => events.add('bomb');
  @override
  void playCombo() => events.add('combo');
  @override
  void playMiss() => events.add('miss');
  @override
  Future<void> playBackgroundMusic() async => events.add('bgm-play');
  @override
  void pauseBackgroundMusic() => events.add('bgm-pause');
  @override
  void resumeBackgroundMusic() => events.add('bgm-resume');
}
```

Then add these tests inside `main()`, after the `'pausing hides controls and resuming restores them'` test:

```dart
  testWithGame<AlaifGame>('background music starts on load',
      () => AlaifGame(audio: RecordingAudio()), (game) async {
    final audio = game.audio as RecordingAudio;
    expect(audio.events, contains('bgm-play'));
  });

  testWithGame<AlaifGame>(
      'pausing and resuming the game pauses/resumes background music',
      () => AlaifGame(audio: RecordingAudio()), (game) async {
    final audio = game.audio as RecordingAudio;
    game.startGame();
    audio.events.clear();

    game.pauseGame();
    expect(audio.events, contains('bgm-pause'));

    game.resumeFromPause();
    expect(audio.events, contains('bgm-resume'));
  });

  testWithGame<AlaifGame>('backgrounding the app pauses background music',
      () => AlaifGame(audio: RecordingAudio()), (game) async {
    final audio = game.audio as RecordingAudio;
    audio.events.clear();

    game.lifecycleStateChange(AppLifecycleState.paused);

    expect(audio.events, contains('bgm-pause'));
  });
```

- [ ] **Step 7: Run the tests to verify they fail**

```bash
flutter test test/game/alaif_game_test.dart
```

Expected: the three new tests FAIL (e.g. `bgm-play` not found in `audio.events`, because `AlaifGame` doesn't call `playBackgroundMusic`/`pauseBackgroundMusic`/`resumeBackgroundMusic` yet).

- [ ] **Step 8: Wire the calls into `AlaifGame`**

In `app/lib/game/alaif_game.dart`:

1. In `onLoad()`, after the line `unawaited(audio.preload()); // fire-and-forget; failures are silent`, add:

```dart
    unawaited(audio.playBackgroundMusic()); // fire-and-forget; failures are silent
```

2. In `pauseGame()`, currently:

```dart
  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    overlays.remove('controls');
    overlays.add('paused');
  }
```

change to:

```dart
  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    audio.pauseBackgroundMusic();
    overlays.remove('controls');
    overlays.add('paused');
  }
```

3. In `resumeFromPause()`, currently:

```dart
  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
  }
```

change to:

```dart
  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
    audio.resumeBackgroundMusic();
  }
```

4. In `lifecycleStateChange()`, currently:

```dart
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) pauseGame();
  }
```

change to:

```dart
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) {
      pauseGame();
      audio.pauseBackgroundMusic();
    }
  }
```

(`pauseGame()` already pauses the music when a round is in progress; the explicit call here also covers backgrounding while on the menu, where `pauseGame()` is a no-op. Calling `pauseBackgroundMusic()` twice is harmless.)

- [ ] **Step 9: Run the tests to verify they pass**

```bash
flutter test test/game/alaif_game_test.dart
```

Expected: all tests pass (PASS), including the three new ones.

- [ ] **Step 10: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass (PASS).

- [ ] **Step 11: Commit**

```bash
git add lib/game/alaif_game.dart test/game/alaif_game_test.dart
git commit -m "feat: start, pause, and resume background music with the game"
```

---

### Task 2: Enable Android haptic feedback (VIBRATE permission)

**Files:**
- Modify: `app/android/app/src/main/AndroidManifest.xml`
- Test: `app/test/android_manifest_test.dart` (new file)

`HapticFeedback` calls in `lib/services/haptics_service.dart` are already wired into slice/bomb/miss events. On Android, `HapticFeedback.heavyImpact()`/`lightImpact()` require the `VIBRATE` permission, which is currently missing from the manifest.

- [ ] **Step 1: Write a failing test asserting the manifest declares VIBRATE**

Create `app/test/android_manifest_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest declares the VIBRATE permission for haptics', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.VIBRATE'));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/android_manifest_test.dart
```

Expected: FAIL — `Expected: contains 'android.permission.VIBRATE' Actual: ...` (the string is not present in the manifest).

- [ ] **Step 3: Add the permission to the manifest**

In `app/android/app/src/main/AndroidManifest.xml`, the file currently starts with:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
```

Change to:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.VIBRATE" />
    <application
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/android_manifest_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml test/android_manifest_test.dart
git commit -m "fix: add VIBRATE permission so Android haptics fire"
```

---

### Task 3: Bomb "ink splat" visual effect on slice

**Files:**
- Modify: `app/lib/ui/design_tokens.dart`
- Modify: `app/lib/core/ink_particles.dart`
- Modify: `app/lib/game/alaif_game.dart`
- Test: `app/test/core/ink_particles_test.dart`
- Test: `app/test/game/alaif_game_test.dart`

Currently, slicing a bomb just calls `bomb.removeFromParent()` — no visual feedback beyond the sound. This task reuses the existing `InkBurstComponent` (already used for letter-cut and combo bursts) with a new, larger/darker "ink splat" particle burst spawned at the bomb's position.

- [ ] **Step 1: Write a failing test for the new particle spawner**

In `app/test/core/ink_particles_test.dart`, add this test inside `main()`, after the `'combo burst spawns comboDustParticles gold-dust glints'` test:

```dart
  test('bomb burst spawns bombInkParticles dark ink splats within the speed range', () {
    final particles = spawnBombBurst(center, Random(7));
    expect(particles.length, AlaifMotion.bombInkParticles);
    for (final p in particles) {
      expect(p.color, AlaifColors.ink);
      expect(p.lifeMs, AlaifMotion.bombParticleLifeMs);
      expect(p.position, center);
      expect(p.velocity.length,
          greaterThanOrEqualTo(AlaifMotion.bombParticleSpeedMin));
      expect(p.velocity.length,
          lessThanOrEqualTo(AlaifMotion.bombParticleSpeedMax));
    }
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/core/ink_particles_test.dart
```

Expected: compile error — `spawnBombBurst`, `AlaifMotion.bombInkParticles`, `AlaifMotion.bombParticleLifeMs`, `AlaifMotion.bombParticleSpeedMin`, `AlaifMotion.bombParticleSpeedMax` don't exist yet.

- [ ] **Step 3: Add bomb burst constants to `AlaifMotion`**

In `app/lib/ui/design_tokens.dart`, find the `AlaifMotion` class. After the block:

```dart
  // Combo — gold dust burst on 3+ in one swipe.
  static const comboDustParticles = 18;
  static const comboFlashMs = 600; // combo callout fade
```

add:

```dart

  // Bomb feedback — dark ink splat thrown when a bomb is sliced. Bigger,
  // slower, and longer-lived than a letter cut, reading as a heavy splash.
  static const bombInkParticles = 24;
  static const bombParticleSpeedMin = 150.0; // px/s
  static const bombParticleSpeedMax = 420.0;
  static const bombParticleLifeMs = 650;
```

- [ ] **Step 4: Generalize `_burst` and add `spawnBombBurst`**

In `app/lib/core/ink_particles.dart`, the private `_burst` helper currently is:

```dart
List<InkParticle> _burst(
  Vector2 center,
  Random random, {
  required int count,
  required Color color,
  required double radiusMin,
  required double radiusMax,
}) {
  return List.generate(count, (_) {
    final angle = random.nextDouble() * 2 * pi;
    final speed = AlaifMotion.cutParticleSpeedMin +
        random.nextDouble() *
            (AlaifMotion.cutParticleSpeedMax - AlaifMotion.cutParticleSpeedMin);
    return InkParticle(
      position: center.clone(),
      velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
      radius: radiusMin + random.nextDouble() * (radiusMax - radiusMin),
      color: color,
      lifeMs: AlaifMotion.cutParticleLifeMs,
    );
  });
}
```

Replace it with a version that accepts speed range and lifetime as optional parameters, defaulting to the existing cut-burst values (so `spawnCutBurst` and `spawnComboBurst` are unaffected):

```dart
List<InkParticle> _burst(
  Vector2 center,
  Random random, {
  required int count,
  required Color color,
  required double radiusMin,
  required double radiusMax,
  double speedMin = AlaifMotion.cutParticleSpeedMin,
  double speedMax = AlaifMotion.cutParticleSpeedMax,
  int lifeMs = AlaifMotion.cutParticleLifeMs,
}) {
  return List.generate(count, (_) {
    final angle = random.nextDouble() * 2 * pi;
    final speed = speedMin + random.nextDouble() * (speedMax - speedMin);
    return InkParticle(
      position: center.clone(),
      velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
      radius: radiusMin + random.nextDouble() * (radiusMax - radiusMin),
      color: color,
      lifeMs: lifeMs,
    );
  });
}
```

Then, after the existing `spawnComboBurst` function at the bottom of the file, add:

```dart

/// Dark ink splat thrown when a bomb is sliced (spec: bomb visual feedback).
/// Bigger, slower, and longer-lived than [spawnCutBurst] so it reads as a
/// heavy splash rather than a clean cut.
List<InkParticle> spawnBombBurst(Vector2 center, Random random) => _burst(
      center,
      random,
      count: AlaifMotion.bombInkParticles,
      color: AlaifColors.ink,
      radiusMin: 3.0,
      radiusMax: 7.0,
      speedMin: AlaifMotion.bombParticleSpeedMin,
      speedMax: AlaifMotion.bombParticleSpeedMax,
      lifeMs: AlaifMotion.bombParticleLifeMs,
    );
```

- [ ] **Step 5: Run the test to verify it passes**

```bash
flutter test test/core/ink_particles_test.dart
```

Expected: PASS, including the new `bomb burst spawns bombInkParticles...` test.

- [ ] **Step 6: Write a failing test for the in-game bomb burst**

In `app/test/game/alaif_game_test.dart`, add this test after the existing `'slicing a bomb costs a life'` test:

```dart
  testWithGame<AlaifGame>('slicing a bomb throws an ink burst', AlaifGame.new,
      (game) async {
    game.startGame();
    game.add(BombComponent(
      motion: ArcMotion(start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    ));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);

    expect(game.children.whereType<InkBurstComponent>().length, 1);
  });
```

- [ ] **Step 7: Run the test to verify it fails**

```bash
flutter test test/game/alaif_game_test.dart
```

Expected: FAIL — `Expected: 1 Actual: 0` (no `InkBurstComponent` is added when a bomb is sliced).

- [ ] **Step 8: Spawn the burst in `trySlice`**

In `app/lib/game/alaif_game.dart`, the bomb-handling loop in `trySlice` currently is:

```dart
    for (final bomb in children.whereType<BombComponent>().toList()) {
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        audio.playBomb();
        _checkGameOver();
      }
    }
```

Change to:

```dart
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
```

`spawnBombBurst` is exported from `../core/ink_particles.dart`, which is already imported in this file (used for `spawnCutBurst`/`spawnComboBurst`) — no new imports needed.

- [ ] **Step 9: Run the tests to verify they pass**

```bash
flutter test test/game/alaif_game_test.dart
```

Expected: PASS, including the new `'slicing a bomb throws an ink burst'` test.

- [ ] **Step 10: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass (PASS).

- [ ] **Step 11: Commit**

```bash
git add lib/ui/design_tokens.dart lib/core/ink_particles.dart lib/game/alaif_game.dart test/core/ink_particles_test.dart test/game/alaif_game_test.dart
git commit -m "feat: add ink-splat visual effect when a bomb is sliced"
```

---

### Task 4: Fix pause button overlapping HUD lives dots

**Files:**
- Modify: `app/lib/ui/controls_overlay.dart`
- Test: `app/test/ui/controls_overlay_test.dart`

The HUD (`lib/game/hud.dart`) draws three 14px lives dots top-right, vertically centered at `AlaifSpacing.lg + 14 + safePadding.top` (= 30px from the safe-area top, with a 7px radius — so the dots span from y=23 to y=37 within the safe area). The pause button (`ControlsOverlay`) is also aligned top-right with only 8px of padding inside its own `SafeArea`, so its ~48x48 tap target (32px icon + IconButton's default 8px padding) overlaps the dots both horizontally and vertically.

The fix: push the pause button down below the lives-dot row by increasing its top padding, so the two no longer occupy the same vertical band.

- [ ] **Step 1: Write a failing test for the new padding**

In `app/test/ui/controls_overlay_test.dart`, add this test after the existing `'controls overlay is positioned top-right via Align'` test:

```dart
  testWidgets(
      'pause button sits below the HUD lives-dot row, clearing the overlap',
      (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: ControlsOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();

    final padding = tester.widget<Padding>(find.ancestor(
      of: find.byType(IconButton),
      matching: find.byType(Padding),
    ));

    // HUD lives dots are centered at y=30 (AlaifSpacing.lg + 14) with a 7px
    // radius, so they end at y=37 within the safe area. The pause button's
    // top padding must clear that.
    expect(padding.padding.resolve(TextDirection.ltr).top, greaterThanOrEqualTo(37));
  });
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/ui/controls_overlay_test.dart
```

Expected: FAIL — current padding is `EdgeInsets.all(8.0)`, so `top` is `8`, which is not `>= 37`.

- [ ] **Step 3: Update the padding in `ControlsOverlay`**

In `app/lib/ui/controls_overlay.dart`, currently:

```dart
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
```

change to:

```dart
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0, right: 8.0),
          child: IconButton(
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/ui/controls_overlay_test.dart
```

Expected: PASS, including the existing two tests and the new one.

- [ ] **Step 5: Run the full test suite**

```bash
flutter test
```

Expected: all tests pass (PASS).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/controls_overlay.dart test/ui/controls_overlay_test.dart
git commit -m "fix: move pause button below HUD lives dots to stop overlap"
```

---

## Final Verification

- [ ] **Step 1: Run the full test suite and analyzer**

```bash
flutter test
flutter analyze
```

Expected: all tests pass (PASS), `flutter analyze` reports "No issues found!".

- [ ] **Step 2: Push the branch and open a PR**

```bash
git push -u origin fix/polish-2
gh pr create --title "Polish: bg music loop, Android haptics, bomb FX, topbar fix" --body "$(cat <<'EOF'
## Summary
- Wire up looping background music (starts on load, pauses with the game and on backgrounding, resumes from pause)
- Add the missing Android VIBRATE permission so existing haptic feedback fires
- Add a dark ink-splat visual effect when a bomb is sliced
- Move the pause button below the HUD lives dots to fix the topbar overlap

## Test plan
- [ ] `flutter test` and `flutter analyze` pass
- [ ] Manual: background music starts on launch, pauses on game pause and app backgrounding, resumes on unpause
- [ ] Manual: haptic buzz on slice/bomb/miss on a physical Android device
- [ ] Manual: bomb ink-splat appears on bomb hit
- [ ] Manual: pause button no longer overlaps lives dots across device sizes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Spec: [[audio-haptics-bomb-topbar-fixes]]
