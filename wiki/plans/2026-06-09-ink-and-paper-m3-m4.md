# Ink & Paper (M3+M4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Take the Alaif game from its placeholder M0–M2 look (dark purple background, gold glyphs, white text) to the full **Ink & Paper** visual design — paper background with girih lattice, near-black ink glyphs in Aref Ruqaa, brush-ink blade, ink-splatter cuts, gold-dust combos, vermillion seal accents — and ship the M3 juice layer (particles, combo callouts, HUD dressing, haptics, audio) plus the M4 menu suite (rebuilt menu/pause/game-over overlays, new how-to and settings overlays, persisted settings).

**Architecture:** Flutter + Flame single-package app at `/Users/iammoo/code/alaif/app`. `lib/core/` holds pure logic (no Flame components beyond `Vector2` math), `lib/game/` holds Flame components and `AlaifGame`, `lib/ui/` holds Flutter overlay widgets + design tokens/theme, `lib/services/` holds persistence/platform wrappers. Design tokens (`AlaifColors`, `AlaifType`, `AlaifMotion`, `AlaifGlyph`, `AlaifSpacing`, `AlaifRadii`, `AlaifFonts`, `AlaifGradients`) are the single source of truth for both the Flame layer (via `TextPaint`/`Paint`) and the Flutter shell (via `buildAlaifTheme()`). Overlays are Flame overlay-map widgets registered in `main.dart` with guarded stub registration in `AlaifGame.onLoad` for tests.

**Tech Stack:** Flutter (Dart SDK ^3.10.4), flame ^1.35.1, flame_audio ^2.11.14 (added in Task 14), shared_preferences ^2.5.5, flame_test ^2.2.2, flutter_test, flutter_lints ^6.0.0. Fonts: Spectral + Aref Ruqaa (vendored TTFs, OFL 1.1). Audio: one real SFX (`assets/audio/slice.mp3`); bomb/combo/miss SFX intentionally absent — `AudioService` tolerates missing files silently.

**Conventions for every task:**
- Run all commands from `/Users/iammoo/code/alaif/app` unless stated otherwise.
- Test command is `flutter test <path>`; full suite is `flutter test`. The pre-existing suite (54 tests) must stay green; tasks that change asserted strings/colors update those tests in the same task.
- Commit after every task with the exact `git commit` shown (conventional commits). The repo root is `/Users/iammoo/code/alaif`; run git commands from there.
- "Append to file" edits show the exact old/new snippets; new files show their complete contents.

---

## Task list

- [ ] Task 1: Vendor design tokens + theme into `lib/ui/`
- [ ] Task 2: Vendor Spectral + ArefRuqaa fonts and declare them in pubspec
- [ ] Task 3: Wrap `MaterialApp` with `buildAlaifTheme()`
- [ ] Task 4: `PaperBackground` component + paper game background
- [ ] Task 5: `GlyphAtlas` ink migration (ArefRuqaa, ink gradient, baked shadow, padding)
- [ ] Task 6: Letter & sliced-half display scaling + tumble lifetime
- [ ] Task 7: `BladeTrail` ink color, width taper, retention
- [ ] Task 8: `BombComponent` ink-and-seal styling
- [ ] Task 9: Ink particle model (`core/ink_particles.dart`)
- [ ] Task 10: `InkBurstComponent` + `ComboCallout` components
- [ ] Task 11: `ScoreState.bestCombo` + wire splatter/combo into `AlaifGame`
- [ ] Task 12: HUD rebuild (SCORE label, ink score, lives dots) + `formatScore`
- [ ] Task 13: `HapticsService` + game wiring
- [ ] Task 14: `AudioService` (flame_audio) + slice SFX asset + game wiring
- [ ] Task 15: `SettingsStore` (sound/music/haptics persistence)
- [ ] Task 16: Game plumbing — apply settings, new overlay stubs, `openSettings`/`openHowTo`/`quitToMenu`
- [ ] Task 17: Menu overlay rebuild (§4.1)
- [ ] Task 18: How-to-play overlay (new, §4.2)
- [ ] Task 19: Pause overlay rebuild (§4.4)
- [ ] Task 20: Game-over overlay rebuild (§4.5)
- [ ] Task 21: Settings overlay (new, §4.6)
- [ ] Task 22: Final verification — full test + analyze pass

---

## Task 1: Vendor design tokens + theme into `lib/ui/`

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart` (copy of `/Users/iammoo/code/alaif/raw/design/deliverables/design_tokens.dart`, unchanged)
- Create: `/Users/iammoo/code/alaif/app/lib/ui/alaif_theme.dart` (copy of `/Users/iammoo/code/alaif/raw/design/deliverables/alaif_theme.dart` with the relative import changed to a package import)
- Test: `/Users/iammoo/code/alaif/app/test/ui/alaif_theme_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/ui/alaif_theme_test.dart`:

```dart
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token palette matches the Ink & Paper spec', () {
    expect(AlaifColors.paper, const Color(0xFFEDE7D8));
    expect(AlaifColors.ink, const Color(0xFF1B1712));
    expect(AlaifColors.seal, const Color(0xFFB23A2B));
    expect(AlaifColors.goldDust, const Color(0xFFC9A24B));
    expect(AlaifColors.bladeInk, const Color(0xE61B1712));
  });

  test('motion tokens carry the M3 tuning values', () {
    expect(AlaifMotion.bladeRetentionMs, 110);
    expect(AlaifMotion.cutInkParticles, 14);
    expect(AlaifMotion.comboFlashMs, 600);
    expect(AlaifGlyph.renderFontSize, 220.0);
    expect(AlaifGlyph.texturePadding, 24.0);
  });

  test('buildAlaifTheme paints paper surfaces and ink primaries', () {
    final theme = buildAlaifTheme();
    expect(theme.scaffoldBackgroundColor, AlaifColors.paper);
    expect(theme.colorScheme.primary, AlaifColors.ink);
    expect(theme.colorScheme.secondary, AlaifColors.seal);
    expect(theme.useMaterial3, isTrue);
  });
}
```

- [ ] Run it and confirm it fails because the files don't exist yet:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/alaif_theme_test.dart
```

Expected output contains a compile error like `Error: Couldn't resolve the package 'alaif/ui/alaif_theme.dart'` / `Target of URI doesn't exist`.

- [ ] Copy the two deliverable files into the app:

```bash
cp /Users/iammoo/code/alaif/raw/design/deliverables/design_tokens.dart /Users/iammoo/code/alaif/app/lib/ui/design_tokens.dart
cp /Users/iammoo/code/alaif/raw/design/deliverables/alaif_theme.dart /Users/iammoo/code/alaif/app/lib/ui/alaif_theme.dart
```

- [ ] Fix the import in `/Users/iammoo/code/alaif/app/lib/ui/alaif_theme.dart`. Old:

```dart
import 'package:flutter/material.dart';
import 'design_tokens.dart';
```

New:

```dart
import 'package:flutter/material.dart';

import 'package:alaif/ui/design_tokens.dart';
```

- [ ] Run the test again and expect all 3 tests to pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/alaif_theme_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite to confirm nothing else broke: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/design_tokens.dart app/lib/ui/alaif_theme.dart app/test/ui/alaif_theme_test.dart && git commit -m "feat(ui): vendor Ink & Paper design tokens and theme"
```

---

## Task 2: Vendor Spectral + ArefRuqaa fonts and declare them in pubspec

**Files:**
- Create: `/Users/iammoo/code/alaif/app/assets/fonts/Spectral-Regular.ttf`, `Spectral-Italic.ttf`, `Spectral-Medium.ttf`, `Spectral-MediumItalic.ttf`, `ArefRuqaa-Regular.ttf`, `ArefRuqaa-Bold.ttf`, `OFL-Spectral.txt`, `OFL-ArefRuqaa.txt` (downloaded, binary — no test-first step for binaries)
- Modify: `/Users/iammoo/code/alaif/app/pubspec.yaml`
- Test: `/Users/iammoo/code/alaif/app/test/ui/font_assets_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/ui/font_assets_test.dart` (flutter tests run with CWD = the app package root, so relative paths resolve against `/Users/iammoo/code/alaif/app`):

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontFiles = [
    'assets/fonts/Spectral-Regular.ttf',
    'assets/fonts/Spectral-Italic.ttf',
    'assets/fonts/Spectral-Medium.ttf',
    'assets/fonts/Spectral-MediumItalic.ttf',
    'assets/fonts/ArefRuqaa-Regular.ttf',
    'assets/fonts/ArefRuqaa-Bold.ttf',
    'assets/fonts/OFL-Spectral.txt',
    'assets/fonts/OFL-ArefRuqaa.txt',
  ];

  test('all vendored font files and licenses exist and are non-empty', () {
    for (final path in fontFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path is missing');
      expect(file.lengthSync(), greaterThan(0), reason: '$path is empty');
    }
  });

  test('pubspec declares both font families and the OFL fonts dir asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Spectral'));
    expect(pubspec, contains('family: ArefRuqaa'));
    expect(pubspec, contains('assets/fonts/Spectral-MediumItalic.ttf'));
    expect(pubspec, contains('assets/fonts/ArefRuqaa-Bold.ttf'));
  });
}
```

- [ ] Run it, expect failure (`assets/fonts/Spectral-Regular.ttf is missing`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/font_assets_test.dart
```

- [ ] Download the fonts and licenses from the google/fonts repo (all OFL 1.1; URLs verified live on 2026-06-10):

```bash
mkdir -p /Users/iammoo/code/alaif/app/assets/fonts
cd /Users/iammoo/code/alaif/app/assets/fonts
curl -fLo Spectral-Regular.ttf       https://raw.githubusercontent.com/google/fonts/main/ofl/spectral/Spectral-Regular.ttf
curl -fLo Spectral-Italic.ttf        https://raw.githubusercontent.com/google/fonts/main/ofl/spectral/Spectral-Italic.ttf
curl -fLo Spectral-Medium.ttf        https://raw.githubusercontent.com/google/fonts/main/ofl/spectral/Spectral-Medium.ttf
curl -fLo Spectral-MediumItalic.ttf  https://raw.githubusercontent.com/google/fonts/main/ofl/spectral/Spectral-MediumItalic.ttf
curl -fLo OFL-Spectral.txt           https://raw.githubusercontent.com/google/fonts/main/ofl/spectral/OFL.txt
curl -fLo ArefRuqaa-Regular.ttf      https://raw.githubusercontent.com/google/fonts/main/ofl/arefruqaa/ArefRuqaa-Regular.ttf
curl -fLo ArefRuqaa-Bold.ttf         https://raw.githubusercontent.com/google/fonts/main/ofl/arefruqaa/ArefRuqaa-Bold.ttf
curl -fLo OFL-ArefRuqaa.txt          https://raw.githubusercontent.com/google/fonts/main/ofl/arefruqaa/OFL.txt
ls -la  # verify all 8 files are non-zero size
```

- [ ] Declare the fonts in `/Users/iammoo/code/alaif/app/pubspec.yaml` (fonts block copied from visual spec §3). Old (end of file):

```yaml
# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true
```

New:

```yaml
# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

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

(Leave the long trailing comment block in pubspec.yaml as-is below the new section — only insert the `fonts:` block right after `uses-material-design: true`.)

- [ ] Refresh the asset bundle and run the test, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter pub get && flutter test test/ui/font_assets_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/assets/fonts app/pubspec.yaml app/test/ui/font_assets_test.dart && git commit -m "feat(ui): vendor Spectral and ArefRuqaa fonts (OFL 1.1) and declare families"
```

---

## Task 3: Wrap `MaterialApp` with `buildAlaifTheme()`

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/main.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/app_theme_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/ui/app_theme_test.dart`:

```dart
import 'package:alaif/main.dart';
import 'package:alaif/ui/design_tokens.dart';
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
}
```

- [ ] Run it, expect the `app.theme, isNotNull` expectation to fail (current `MaterialApp` has no `theme:`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/app_theme_test.dart
```

Expected: `Expected: not null  Actual: <null>` … `Some tests failed.`

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/main.dart`. Old:

```dart
import 'game/alaif_game.dart';
import 'ui/controls_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
```

New:

```dart
import 'game/alaif_game.dart';
import 'ui/alaif_theme.dart';
import 'ui/controls_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
```

Old:

```dart
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
```

New:

```dart
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlaifTheme(),
      home: Scaffold(
```

- [ ] Run the test again, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/app_theme_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/main.dart app/test/ui/app_theme_test.dart && git commit -m "feat(ui): apply buildAlaifTheme to the app shell"
```

---

## Task 4: `PaperBackground` component + paper game background

The game canvas flips from dark purple to paper. `PaperBackground` paints the paper gradient every frame plus a girih-lattice tile (two overlapped squares = 8-point star) that is pre-rendered **once** to a `ui.Image` in `onLoad` and painted via `ImageShader` (~2 draw calls/frame, per spec §6). If tile generation throws, the component silently falls back to gradient-only paper.

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/game/paper_background.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/paper_background_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/game/paper_background_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/paper_background.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('lattice tile renders to a square non-empty image', () async {
    final tile = await PaperBackground.buildLatticeTile();
    expect(tile.width, PaperBackground.tileSize);
    expect(tile.height, PaperBackground.tileSize);
  });

  testWithGame<AlaifGame>('game background is paper and PaperBackground is mounted',
      AlaifGame.new, (game) async {
    expect(game.backgroundColor(), AlaifColors.paper);
    final bg = game.children.whereType<PaperBackground>().single;
    expect(bg.hasLattice, isTrue);
    expect(bg.size, game.size);
    expect(bg.priority, lessThan(0)); // renders under everything
  });

  testWithGame<AlaifGame>('PaperBackground render does not throw',
      AlaifGame.new, (game) async {
    final bg = game.children.whereType<PaperBackground>().single;
    final recorder = ui.PictureRecorder();
    bg.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
```

- [ ] Run it, expect a compile failure (`Target of URI doesn't exist: 'package:alaif/game/paper_background.dart'`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/paper_background_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/game/paper_background.dart` with this complete content:

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Full-screen paper background: vertical paper gradient + a faint girih
/// lattice (two overlapped squares = 8-point star) tiled via an ImageShader.
///
/// The lattice tile is pre-rendered ONCE to a [ui.Image] in [onLoad]; if that
/// fails for any reason the component silently falls back to gradient-only
/// paper (spec §6 fallback).
class PaperBackground extends PositionComponent with HasGameReference<AlaifGame> {
  PaperBackground() : super(priority: -100);

  /// Side length in px of the square lattice tile.
  static const tileSize = 96;

  /// ~5% ink — the lattice must stay a whisper under the gameplay.
  static const _latticeInk = ui.Color(0x0D1B1712);

  static final Float64List _identityMatrix4 = Float64List.fromList(const [
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);

  ui.Image? _tile;

  /// True when the lattice tile rendered successfully (false = solid fallback).
  bool get hasLattice => _tile != null;

  /// Renders one girih tile: an axis-aligned square overlapped by a 45-degree
  /// rotated square, hairline-stroked — tiled, this reads as 8-point stars.
  static Future<ui.Image> buildLatticeTile({int size = tileSize}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = _latticeInk
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    final s = size.toDouble();
    final center = ui.Offset(s / 2, s / 2);
    final half = s * 0.38;
    canvas.drawRect(ui.Rect.fromCircle(center: center, radius: half), paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      ui.Rect.fromCircle(center: ui.Offset.zero, radius: half),
      paint,
    );
    canvas.restore();
    return recorder.endRecording().toImage(size, size);
  }

  @override
  Future<void> onLoad() async {
    position = Vector2.zero();
    size = game.size.clone();
    try {
      _tile = await buildLatticeTile();
    } catch (_) {
      _tile = null; // solid-paper fallback; never fatal
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      rect,
      ui.Paint()..shader = AlaifGradients.paper.createShader(rect),
    );
    final tile = _tile;
    if (tile != null) {
      canvas.drawRect(
        rect,
        ui.Paint()
          ..shader = ui.ImageShader(
            tile,
            ui.TileMode.repeated,
            ui.TileMode.repeated,
            _identityMatrix4,
          ),
      );
    }
  }
}
```

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. Old:

```dart
import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'sliced_halves.dart';
import 'spawner.dart';
```

New:

```dart
import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'paper_background.dart';
import 'sliced_halves.dart';
import 'spawner.dart';
```

Old:

```dart
  @override
  Color backgroundColor() => const Color(0xFF120C1D);

  @override
  Future<void> onLoad() async {
    await atlas.load();
```

New:

```dart
  @override
  Color backgroundColor() => AlaifColors.paper;

  @override
  Future<void> onLoad() async {
    await atlas.load();
    await add(PaperBackground());
```

(Note: `alaif_game.dart` imports `dart:ui`'s `Color` via `import 'dart:ui';` — `AlaifColors.paper` is a Flutter `Color`, which IS `dart:ui`'s `Color`, so the return type still matches.)

- [ ] Run the test again, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/paper_background_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/paper_background.dart app/lib/game/alaif_game.dart app/test/game/paper_background_test.dart && git commit -m "feat(game): paper background with cached girih lattice ImageShader"
```

---

## Task 5: `GlyphAtlas` ink migration

Replace the gold→orange glyph gradient with `AlaifGradients.glyph` (ink), render with `ArefRuqaa` at `AlaifGlyph.renderFontSize`, bake the soft drop shadow (`AlaifGlyph.shadowBlur/shadowOffsetY/shadowColor`) and pad the texture by `AlaifGlyph.texturePadding` so neither gradient nor shadow clip.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart`
- Test: `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart` (extend)

**Steps:**

- [ ] Extend `/Users/iammoo/code/alaif/app/test/core/glyph_atlas_test.dart`. Old:

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
```

New:

```dart
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
```

- [ ] Run it, expect the two new tests to fail (no padding; gold pixels found):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart
```

Expected: `Some tests failed.` with `expected near-black ink pixels` among the failures.

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/core/glyph_atlas.dart` with:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';

/// Pre-renders the 28 Arabic letters (isolated forms) to textures at load.
///
/// Ink & Paper: glyphs render in ArefRuqaa at [AlaifGlyph.renderFontSize]
/// with the vertical ink gradient [AlaifGradients.glyph] and a soft baked
/// drop shadow, padded by [AlaifGlyph.texturePadding] so nothing clips.
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
}
```

- [ ] Run the glyph tests again, expect pass (the old 4 tests + 2 new):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/glyph_atlas_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite — everything must still pass (letters are bigger textures now but no test asserts glyph dimensions): `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/core/glyph_atlas.dart app/test/core/glyph_atlas_test.dart && git commit -m "feat(game): render glyph atlas as ArefRuqaa ink with baked shadow and padding"
```

---

## Task 6: Letter & sliced-half display scaling + tumble lifetime

Task 5 made textures ~2× bigger (render at 220px for crispness). Per spec §7.4 we now **scale down per spawn**: `LetterComponent` gets a `targetSize` (longest on-screen edge, drawn via `drawImageRect`), the spawner picks it from `AlaifGlyph.spawnSizeMin..spawnSizeMax`, and `SlicedHalf` accepts the letter's on-screen `displaySize` so halves match the letter they came from. `SlicedHalf` also gains the `AlaifMotion.cutHalfTumbleMs` lifetime (spec §4.3) so halves never linger.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/spawner.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/components_test.dart` (extend + update one assertion)

**Steps:**

- [ ] Update `/Users/iammoo/code/alaif/app/test/game/components_test.dart`. First add the new imports. Old:

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
```

New:

```dart
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

Then update the hit-radius test (the texture no longer dictates on-screen size). Old:

```dart
  test('letter hit radius derives from its size', () async {
    final image = await testImage(width: 80, height: 80);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
    );
    expect(letter.hitRadius, 40);
  });
```

New:

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

  test('letter defaults to the max spawn size from the tokens', () async {
    final image = await testImage(width: 200, height: 200);
    final letter = LetterComponent(
      letter: 'ب',
      image: image,
      motion: ArcMotion(start: Vector2.zero(), velocity: Vector2.zero()),
    );
    expect(letter.size.x, AlaifGlyph.spawnSizeMax);
  });

  testWithGame<AlaifGame>('sliced half is removed after cutHalfTumbleMs',
      AlaifGame.new, (game) async {
    SharedPreferences.setMockInitialValues({});
    final image = await testImage();
    final half = SlicedHalf(
      image: image,
      startPosition: Vector2(100, 100),
      velocity: Vector2.zero(),
      topHalf: true,
      removeBelowY: 100000, // never trips the off-screen rule in this test
    );
    await game.add(half);
    game.update(0);
    expect(game.children.whereType<SlicedHalf>().length, 1);

    game.update(AlaifMotion.cutHalfTumbleMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<SlicedHalf>(), isEmpty);
  });
```

(Keep the existing `letter follows its arc` and `sliced half falls` tests untouched.)

- [ ] Run it, expect compile failure (`No named parameter with the name 'targetSize'`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/letter_component.dart` with:

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
  }) : _image = image {
    final longest = math.max(image.width, image.height).toDouble();
    final scale = targetSize / longest;
    size = Vector2(image.width * scale, image.height * scale);
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
  /// Circular hit approximation using half-width; tall glyphs have a smaller vertical hit extent by design.
  double get hitRadius => size.x / 2;

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

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/sliced_halves.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';

/// One half of a sliced glyph, clipped from the full texture, tumbling away.
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
  })  : _image = image,
        _velocity = velocity.clone() {
    size = displaySize?.clone() ??
        Vector2(image.width.toDouble(), image.height.toDouble());
    anchor = Anchor.center;
    position = startPosition.clone();
  }

  static const gravity = 900.0;
  static const spin = 3.0;

  final ui.Image _image;
  final Vector2 _velocity;
  final bool topHalf;
  final double removeBelowY;
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
    final clip = topHalf
        ? ui.Rect.fromLTWH(0, 0, size.x, size.y / 2)
        : ui.Rect.fromLTWH(0, size.y / 2, size.x, size.y / 2);
    canvas.save();
    canvas.clipRect(clip);
    canvas.drawImageRect(
      _image,
      ui.Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, size.x, size.y),
      ui.Paint(),
    );
    canvas.restore();
  }
}
```

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/game/spawner.dart` so spawns pick a size from the tokens. Old:

```dart
import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
```

New:

```dart
import '../core/arc_motion.dart';
import '../core/difficulty_curve.dart';
import '../core/glyph_atlas.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
```

Old:

```dart
      final letter =
          GlyphAtlas.letters[_random.nextInt(GlyphAtlas.letters.length)];
      game.add(LetterComponent(
        letter: letter,
        image: game.atlas.imageFor(letter),
        motion: motion,
      ));
```

New:

```dart
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
```

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart` so halves inherit the letter's on-screen size. Old:

```dart
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
```

New:

```dart
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
```

- [ ] Run the component tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/components_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/letter_component.dart app/lib/game/sliced_halves.dart app/lib/game/spawner.dart app/lib/game/alaif_game.dart app/test/game/components_test.dart && git commit -m "feat(game): per-spawn glyph scaling and cutHalfTumbleMs half lifetime"
```

---

## Task 7: `BladeTrail` ink color, width taper, retention

The blade becomes a dark brush-ink stroke: `AlaifColors.bladeInk`, tapering from `AlaifMotion.bladeWidth` (head) to `AlaifMotion.bladeMinWidth` (tail), with points retained for `AlaifMotion.bladeRetentionMs`.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/blade_trail.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/blade_trail_test.dart` (extend)

**Steps:**

- [ ] Extend `/Users/iammoo/code/alaif/app/test/game/blade_trail_test.dart`. Old:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/blade_trail.dart';
import 'package:alaif/game/hud.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

New:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/blade_trail.dart';
import 'package:alaif/game/hud.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

Old:

```dart
  testWithGame<AlaifGame>('blade trail covers the full screen', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.size, game.size);
  });
}
```

New:

```dart
  testWithGame<AlaifGame>('blade trail covers the full screen', AlaifGame.new,
      (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.size, game.size);
  });

  testWithGame<AlaifGame>('blade trail retains points for bladeRetentionMs',
      AlaifGame.new, (game) async {
    game.startGame();
    game.update(0);
    final trail = game.children.whereType<BladeTrail>().single;
    expect(trail.buffer.maxAge,
        closeTo(AlaifMotion.bladeRetentionMs / 1000, 1e-9));
  });

  test('stroke width tapers from bladeMinWidth (tail) to bladeWidth (head)', () {
    expect(BladeTrail.strokeWidthFor(1, 1), AlaifMotion.bladeWidth); // lone segment
    expect(BladeTrail.strokeWidthFor(1, 10), AlaifMotion.bladeMinWidth); // tail
    expect(BladeTrail.strokeWidthFor(10, 10), AlaifMotion.bladeWidth); // head
    // Monotonic toward the head.
    expect(BladeTrail.strokeWidthFor(5, 10),
        greaterThan(BladeTrail.strokeWidthFor(2, 10)));
  });
}
```

- [ ] Run it, expect failure (`The method 'strokeWidthFor' isn't defined` compile error):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/blade_trail_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/blade_trail.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/trail_buffer.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Full-screen drag catcher: records the swipe, draws the brush-ink trail,
/// and reports each new segment to the game for slicing.
class BladeTrail extends PositionComponent
    with DragCallbacks, HasGameReference<AlaifGame> {
  final TrailBuffer buffer =
      TrailBuffer(maxAge: AlaifMotion.bladeRetentionMs / 1000);
  double _time = 0;

  /// Stroke width for segment [segmentIndex] (1-based) of [segmentCount]
  /// segments. Linear taper: segment 1 (tail, oldest) = bladeMinWidth,
  /// segment [segmentCount] (head, newest) = bladeWidth.
  static double strokeWidthFor(int segmentIndex, int segmentCount) {
    if (segmentCount <= 1) return AlaifMotion.bladeWidth;
    final t = (segmentIndex - 1) / (segmentCount - 1);
    return AlaifMotion.bladeMinWidth +
        (AlaifMotion.bladeWidth - AlaifMotion.bladeMinWidth) * t;
  }

  @override
  void onLoad() {
    position = Vector2.zero();
    size = game.size.clone();
    priority = 100;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    _time += dt;
    buffer.prune(_time);
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (game.paused) return;
    super.onDragStart(event);
    buffer.clear();
    buffer.add(event.localPosition, _time);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.paused) return; // ignore swipes while the pause overlay is up
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
    final segmentCount = pts.length - 1;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1].position;
      final b = pts[i].position;
      canvas.drawLine(
        ui.Offset(a.x, a.y),
        ui.Offset(b.x, b.y),
        ui.Paint()
          ..color = AlaifColors.bladeInk
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = strokeWidthFor(i, segmentCount)
          ..strokeCap = ui.StrokeCap.round,
      );
    }
  }
}
```

(`i` runs 1..pts.length-1, which is exactly 1..segmentCount: segment 1 = tail = thinnest, segment `segmentCount` = head = full `bladeWidth`.)

- [ ] Run the blade tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/blade_trail_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/blade_trail.dart app/test/game/blade_trail_test.dart && git commit -m "feat(game): brush-ink blade trail with width taper and token retention"
```

---

## Task 8: `BombComponent` ink-and-seal styling

Bombs become a dark radial **ink sphere** with a 2px `seal` ring (the danger cue), a short fuse with a flickering `goldDust` spark, and a paper-colored `!` cut into the ink (spec §4.3).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/bomb_component.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/bomb_component_test.dart` (new file)

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/game/bomb_component_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BombComponent staticBomb() => BombComponent(
        motion: ArcMotion(
          start: Vector2(100, 100),
          velocity: Vector2.zero(),
          gravity: 0,
        ),
      );

  test('bomb ring is seal red with a 2px stroke', () {
    expect(BombComponent.ringColor, AlaifColors.seal);
    expect(BombComponent.ringStrokeWidth, 2.0);
  });

  test('bomb spark is gold dust', () {
    expect(BombComponent.sparkColor, AlaifColors.goldDust);
  });

  test('bomb keeps its motion and hit radius behaviour', () {
    final bomb = staticBomb();
    expect(bomb.hitRadius, 40);
    bomb.update(1.0);
    expect(bomb.position, Vector2(100, 100));
  });

  test('bomb render does not throw', () {
    final bomb = staticBomb();
    bomb.update(0.123); // advance the spark flicker phase
    final recorder = ui.PictureRecorder();
    bomb.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();
  });
}
```

- [ ] Run it, expect compile failure (`Member not found: 'ringColor'`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/bomb_component_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/bomb_component.dart` with:

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

/// Ink & Paper bomb: dark radial ink sphere, 2px seal danger ring, a short
/// fuse with a flickering gold-dust spark, and a paper "!" cut into the ink.
class BombComponent extends PositionComponent {
  BombComponent({required this.motion}) {
    size = Vector2.all(80);
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  static const ringColor = AlaifColors.seal;
  static const ringStrokeWidth = 2.0;
  static const sparkColor = AlaifColors.goldDust;

  /// "!" laid out once and reused by every bomb (no per-frame text layout).
  static final TextPainter _exclaim = TextPainter(
    text: const TextSpan(
      text: '!',
      style: TextStyle(
        fontFamily: AlaifFonts.ui,
        fontSize: 30,
        fontWeight: FontWeight.w500,
        color: AlaifColors.onInk,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final ArcMotion motion;
  double _age = 0;
  bool entered = false;

  /// Circular hit approximation using half-width; tall glyphs have a smaller vertical hit extent by design.
  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - ringStrokeWidth;

    // Ink sphere with a faint top-light so it reads as a sphere, not a dot.
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.3, -radius * 0.35),
          radius * 1.6,
          const [AlaifColors.glyphTop, AlaifColors.ink],
        ),
    );

    // Seal danger ring.
    canvas.drawCircle(
      center,
      radius,
      ui.Paint()
        ..color = ringColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = ringStrokeWidth,
    );

    // Short fuse line out the top-right + flickering gold-dust spark.
    final fuseStart = center.translate(radius * 0.5, -radius * 0.75);
    final fuseEnd = center.translate(radius * 0.8, -radius * 1.15);
    canvas.drawLine(
      fuseStart,
      fuseEnd,
      ui.Paint()
        ..color = AlaifColors.ink
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = ui.StrokeCap.round,
    );
    final flicker = 2.5 + math.sin(_age * 18) * 1.0;
    canvas.drawCircle(fuseEnd, flicker, ui.Paint()..color = sparkColor);

    // Paper "!" cut into the ink.
    _exclaim.paint(
      canvas,
      center.translate(-_exclaim.width / 2, -_exclaim.height / 2),
    );
  }
}
```

- [ ] Run the bomb tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/bomb_component_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite (alaif_game_test slices bombs but never asserts their colors): `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/bomb_component.dart app/test/game/bomb_component_test.dart && git commit -m "feat(game): ink sphere bomb with seal ring and gold-dust fuse spark"
```

---

## Task 9: Ink particle model (`core/ink_particles.dart`)

Pure-math particle layer (testable without Flame mounting): `InkParticle` plus two spawn functions — `spawnCutBurst` (14 ink dots, spec cut feedback) and `spawnComboBurst` (18 gold-dust glints). Rendering lives in Task 10's component; this file has zero canvas code. (Design note: the M3/M4 design's file map put "burst" in `core/ink_particles.dart` — we keep the *model* here and put the Flame component in `game/ink_burst_component.dart`, matching the repo's existing core-vs-game split, e.g. `trail_buffer.dart` vs `blade_trail.dart`.)

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/core/ink_particles.dart`
- Test: `/Users/iammoo/code/alaif/app/test/core/ink_particles_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/core/ink_particles_test.dart`:

```dart
import 'dart:math';

import 'package:alaif/core/ink_particles.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final center = Vector2(100, 200);

  test('cut burst spawns cutInkParticles ink dots within the speed range', () {
    final particles = spawnCutBurst(center, Random(7));
    expect(particles.length, AlaifMotion.cutInkParticles);
    for (final p in particles) {
      expect(p.color, AlaifColors.ink);
      expect(p.lifeMs, AlaifMotion.cutParticleLifeMs);
      expect(p.position, center);
      expect(p.velocity.length,
          greaterThanOrEqualTo(AlaifMotion.cutParticleSpeedMin));
      expect(p.velocity.length,
          lessThanOrEqualTo(AlaifMotion.cutParticleSpeedMax));
    }
  });

  test('combo burst spawns comboDustParticles gold-dust glints', () {
    final particles = spawnComboBurst(center, Random(7));
    expect(particles.length, AlaifMotion.comboDustParticles);
    for (final p in particles) {
      expect(p.color, AlaifColors.goldDust);
    }
  });

  test('particles move, age, fade, and die', () {
    final p = InkParticle(
      position: Vector2.zero(),
      velocity: Vector2(100, 0),
      radius: 2,
      color: AlaifColors.ink,
      lifeMs: 500,
    );
    expect(p.opacity, 1.0);
    p.update(0.25); // 250ms
    expect(p.position.x, closeTo(25, 1e-6));
    expect(p.velocity.y, greaterThan(0)); // gravity pulls down
    expect(p.opacity, closeTo(0.5, 1e-6));
    expect(p.dead, isFalse);
    p.update(0.3); // 550ms total
    expect(p.dead, isTrue);
    expect(p.opacity, 0.0);
  });
}
```

- [ ] Run it, expect compile failure (`Target of URI doesn't exist: 'package:alaif/core/ink_particles.dart'`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/ink_particles_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/core/ink_particles.dart` with this complete content:

```dart
import 'dart:math';
import 'dart:ui' show Color;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';

/// One splatter dot: pure math, rendered by InkBurstComponent (game layer).
class InkParticle {
  InkParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.lifeMs,
  });

  /// Light gravity so splatter falls like flicked ink, not confetti.
  static const gravity = 600.0;

  final Vector2 position;
  final Vector2 velocity;
  final double radius;
  final Color color;
  final int lifeMs;
  double ageMs = 0;

  bool get dead => ageMs >= lifeMs;

  /// Linear fade-out over the particle's life.
  double get opacity => dead ? 0.0 : 1.0 - ageMs / lifeMs;

  void update(double dt) {
    ageMs += dt * 1000;
    position.add(velocity * dt);
    velocity.y += gravity * dt;
  }
}

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

/// Ink splatter thrown when a letter is cut (spec §4.3).
List<InkParticle> spawnCutBurst(Vector2 center, Random random) => _burst(
      center,
      random,
      count: AlaifMotion.cutInkParticles,
      color: AlaifColors.ink,
      radiusMin: 1.5,
      radiusMax: 4.0,
    );

/// Gold-dust glints thrown on a 3+ combo (spec §4.3).
List<InkParticle> spawnComboBurst(Vector2 center, Random random) => _burst(
      center,
      random,
      count: AlaifMotion.comboDustParticles,
      color: AlaifColors.goldDust,
      radiusMin: 1.0,
      radiusMax: 2.5,
    );
```

- [ ] Run the particle tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/ink_particles_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/core/ink_particles.dart app/test/core/ink_particles_test.dart && git commit -m "feat(core): ink splatter and gold-dust particle model"
```

---

## Task 10: `InkBurstComponent` + `ComboCallout` components

Two short-lived Flame components: `InkBurstComponent` draws a list of `InkParticle`s as fading circles in **absolute game coordinates** and removes itself when all particles are dead; `ComboCallout` shows the combo line ("three in a row" / "×N") centered at y≈150 in `AlaifType.combo` (seal italic), scaling up slightly while fading over `AlaifMotion.comboFlashMs`.

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/game/ink_burst_component.dart`
- Create: `/Users/iammoo/code/alaif/app/lib/game/combo_callout.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/juice_components_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/game/juice_components_test.dart`:

```dart
import 'dart:math';
import 'dart:ui' as ui;

import 'package:alaif/core/ink_particles.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/ui/design_tokens.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWithGame<AlaifGame>('ink burst renders then removes itself when spent',
      AlaifGame.new, (game) async {
    final burst =
        InkBurstComponent(particles: spawnCutBurst(Vector2(50, 50), Random(1)));
    await game.add(burst);
    game.update(0);
    expect(game.children.whereType<InkBurstComponent>().length, 1);

    final recorder = ui.PictureRecorder();
    burst.render(ui.Canvas(recorder));
    recorder.endRecording().dispose();

    game.update(AlaifMotion.cutParticleLifeMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<InkBurstComponent>(), isEmpty);
  });

  test('comboText spells small chains and counts big ones', () {
    expect(ComboCallout.comboText(3), 'three in a row');
    expect(ComboCallout.comboText(4), 'four in a row');
    expect(ComboCallout.comboText(5), '×5');
    expect(ComboCallout.comboText(9), '×9');
  });

  testWithGame<AlaifGame>('combo callout centers near y150 and fades away',
      AlaifGame.new, (game) async {
    final callout = ComboCallout(text: 'three in a row');
    await game.add(callout);
    game.update(0);
    expect(callout.position.x, game.size.x / 2);
    expect(callout.position.y, 150);
    expect(callout.anchor, Anchor.center);

    game.update(AlaifMotion.comboFlashMs / 1000 + 0.05);
    game.update(0); // flush removal queue
    expect(game.children.whereType<ComboCallout>(), isEmpty);
  });
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/game/ink_burst_component.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/juice_components_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/game/ink_burst_component.dart` with this complete content:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/ink_particles.dart';

/// Renders a one-shot particle burst (ink splatter or gold dust).
///
/// Particle positions are absolute game coordinates, so this component sits
/// at the origin and simply draws every live particle each frame. It removes
/// itself once every particle is dead.
class InkBurstComponent extends Component {
  InkBurstComponent({required this.particles}) {
    priority = 60; // over letters (default 0), under the blade (100)
  }

  final List<InkParticle> particles;

  @override
  void update(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    if (particles.every((p) => p.dead)) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    for (final p in particles) {
      if (p.dead) continue;
      canvas.drawCircle(
        ui.Offset(p.position.x, p.position.y),
        p.radius,
        ui.Paint()..color = p.color.withValues(alpha: p.opacity),
      );
    }
  }
}
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/game/combo_callout.dart` with this complete content:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Centered combo line ("three in a row" / "×N"): seal italic, scales up
/// slightly while fading out over [AlaifMotion.comboFlashMs], then removes
/// itself (spec §4.3).
class ComboCallout extends PositionComponent with HasGameReference<AlaifGame> {
  ComboCallout({required this.text}) : super(priority: 95);

  final String text;
  double _ageMs = 0;
  late final TextPainter _painter;

  /// Spell out the chains the spec names; bigger chains read as a counter.
  static String comboText(int hits) {
    switch (hits) {
      case 3:
        return 'three in a row';
      case 4:
        return 'four in a row';
      default:
        return '×$hits'; // ×N
    }
  }

  @override
  Future<void> onLoad() async {
    _painter = TextPainter(
      text: TextSpan(text: text, style: AlaifType.combo),
      textDirection: TextDirection.ltr,
    )..layout();
    size = Vector2(_painter.width, _painter.height);
    anchor = Anchor.center;
    position = Vector2(game.size.x / 2, 150);
  }

  @override
  void update(double dt) {
    _ageMs += dt * 1000;
    if (_ageMs >= AlaifMotion.comboFlashMs) {
      removeFromParent();
      return;
    }
    final t = _ageMs / AlaifMotion.comboFlashMs;
    scale = Vector2.all(1 + 0.15 * t);
  }

  @override
  void render(ui.Canvas canvas) {
    final t = (_ageMs / AlaifMotion.comboFlashMs).clamp(0.0, 1.0);
    final bounds = ui.Rect.fromLTWH(0, 0, size.x, size.y).inflate(8);
    canvas.saveLayer(
      bounds,
      ui.Paint()..color = const ui.Color(0xFF000000).withValues(alpha: 1 - t),
    );
    _painter.paint(canvas, ui.Offset.zero);
    canvas.restore();
  }
}
```

- [ ] Run the juice-component tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/juice_components_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/ink_burst_component.dart app/lib/game/combo_callout.dart app/test/game/juice_components_test.dart && git commit -m "feat(game): ink burst and combo callout components"
```

---

## Task 11: `ScoreState.bestCombo` + wire splatter/combo into `AlaifGame`

Cuts throw ink at the letter's position; lifting the finger after a 3+ chain throws gold dust at the last cut and shows the combo callout. `ScoreState` starts tracking the run's best combo (the game-over overlay shows it in Task 20).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/core/score_state.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/core/score_state_test.dart` (extend), `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` (extend)

**Steps:**

- [ ] Append these tests inside `main()` (before the closing `}`) of `/Users/iammoo/code/alaif/app/test/core/score_state_test.dart` — read the file first to confirm the closing brace context, then add:

```dart
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
    expect(state.bestCombo, 3); // smaller swipe doesn't shrink it
  });

  test('reset clears bestCombo', () {
    final state = ScoreState();
    state.registerHit();
    state.registerHit();
    state.registerHit();
    state.endSwipe();
    state.reset();
    expect(state.bestCombo, 0);
  });
```

- [ ] Append these tests inside `main()` (before the closing `}`) of `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`, and extend its imports. Old import block top:

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
```

New:

```dart
import 'package:alaif/core/arc_motion.dart';
import 'package:alaif/core/score_state.dart';
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/bomb_component.dart';
import 'package:alaif/game/combo_callout.dart';
import 'package:alaif/game/ink_burst_component.dart';
import 'package:alaif/game/letter_component.dart';
import 'package:alaif/game/sliced_halves.dart';
```

New tests to append:

```dart
  testWithGame<AlaifGame>('slicing a letter throws an ink burst',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    game.update(0);

    expect(game.children.whereType<InkBurstComponent>().length, 1);
  });

  testWithGame<AlaifGame>('a 3-letter swipe shows the combo callout and gold dust',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.add(staticLetter(game, x: 280));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.update(0);
    game.endSwipe();
    game.update(0);

    final callouts = game.children.whereType<ComboCallout>().toList();
    expect(callouts.length, 1);
    expect(callouts.single.text, 'three in a row');
    // One ink burst per letter + one gold-dust combo burst.
    expect(game.children.whereType<InkBurstComponent>().length, 4);
    expect(game.scoreState.bestCombo, 3);
  });

  testWithGame<AlaifGame>('a 2-letter swipe shows no combo callout',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.update(0);

    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.update(0);
    game.endSwipe();
    game.update(0);

    expect(game.children.whereType<ComboCallout>(), isEmpty);
  });
```

- [ ] Run both, expect failures (`The getter 'bestCombo' isn't defined`; missing combo components):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/score_state_test.dart test/game/alaif_game_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/core/score_state.dart` with:

```dart
class ScoreState {
  static const pointsPerLetter = 10;
  static const comboThreshold = 3;
  static const comboBonusPerLetter = 5;

  int _score = 0;
  int _hitsInSwipe = 0;
  int _bestCombo = 0;

  int get score => _score;
  int get hitsInSwipe => _hitsInSwipe;

  /// Largest chain (hits in a single swipe) seen this run.
  int get bestCombo => _bestCombo;

  void registerHit() {
    _hitsInSwipe += 1;
    _score += pointsPerLetter;
  }

  void endSwipe() {
    if (_hitsInSwipe > _bestCombo) _bestCombo = _hitsInSwipe;
    if (_hitsInSwipe >= comboThreshold) {
      _score += _hitsInSwipe * comboBonusPerLetter;
    }
    _hitsInSwipe = 0;
  }

  void reset() {
    _score = 0;
    _hitsInSwipe = 0;
    _bestCombo = 0;
  }
}
```

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. Add imports — old:

```dart
import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, SizedBox;

import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
import 'bomb_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'paper_background.dart';
import 'sliced_halves.dart';
import 'spawner.dart';
```

New:

```dart
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, SizedBox;

import '../core/game_rules.dart';
import '../core/glyph_atlas.dart';
import '../core/hit_test.dart';
import '../core/ink_particles.dart';
import '../core/score_state.dart';
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
import 'bomb_component.dart';
import 'combo_callout.dart';
import 'ink_burst_component.dart';
import 'letter_component.dart';
import 'blade_trail.dart';
import 'hud.dart';
import 'paper_background.dart';
import 'sliced_halves.dart';
import 'spawner.dart';
```

Update the constructor and fields — old:

```dart
class AlaifGame extends FlameGame {
  AlaifGame({HighScoreStore? highScores})
      : highScores = highScores ?? HighScoreStore();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;
```

New:

```dart
class AlaifGame extends FlameGame {
  AlaifGame({HighScoreStore? highScores, Random? random})
      : highScores = highScores ?? HighScoreStore(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;
  final Random _random;
  Vector2? _lastSlicePosition;
```

Update `endSwipe` — old:

```dart
  /// Called by BladeTrail when the finger lifts.
  void endSwipe() => scoreState.endSwipe();
```

New:

```dart
  /// Called by BladeTrail when the finger lifts. A 3+ chain earns gold dust
  /// at the last cut plus the centered combo callout (spec §4.3).
  void endSwipe() {
    final hits = scoreState.hitsInSwipe;
    scoreState.endSwipe();
    if (!_playing || hits < ScoreState.comboThreshold) return;
    final at = _lastSlicePosition;
    if (at != null) {
      add(InkBurstComponent(particles: spawnComboBurst(at, _random)));
    }
    add(ComboCallout(text: ComboCallout.comboText(hits)));
  }
```

Update `_sliceLetter` — old:

```dart
  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    letter.removeFromParent();
    final cutoff = size.y + 200;
```

New:

```dart
  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    letter.removeFromParent();
    _lastSlicePosition = letter.position.clone();
    add(InkBurstComponent(
      particles: spawnCutBurst(letter.position, _random),
    ));
    final cutoff = size.y + 200;
```

- [ ] Run the two test files again, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/score_state_test.dart test/game/alaif_game_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/core/score_state.dart app/lib/game/alaif_game.dart app/test/core/score_state_test.dart app/test/game/alaif_game_test.dart && git commit -m "feat(game): ink splatter on cut, gold-dust combo burst, callout, bestCombo"
```

---

## Task 12: HUD rebuild (SCORE label, ink score, lives dots) + `formatScore`

Replace the single white debug `TextComponent` with the spec §4.3 HUD: tracked "SCORE" label + comma-grouped score in `AlaifType.scoreHud` top-left, and lives top-right as three 14px dots (filled ink = alive, hairline ring = lost). The `GameWidget` already sits inside a `SafeArea` (see `main.dart`), so token spacing from (0,0) is safe-area aware. `formatScore` lives in a new pure-core file so overlays reuse it later.

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/core/score_format.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/hud.dart`
- Test: `/Users/iammoo/code/alaif/app/test/core/score_format_test.dart`, `/Users/iammoo/code/alaif/app/test/game/hud_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/core/score_format_test.dart`:

```dart
import 'package:alaif/core/score_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatScore groups thousands with commas', () {
    expect(formatScore(0), '0');
    expect(formatScore(7), '7');
    expect(formatScore(999), '999');
    expect(formatScore(8640), '8,640');
    expect(formatScore(14820), '14,820');
    expect(formatScore(1234567), '1,234,567');
  });
}
```

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/game/hud_test.dart`:

```dart
import 'dart:ui' as ui;

import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/game/hud.dart';
import 'package:flame_test/flame_test.dart';
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
}
```

- [ ] Run both, expect failure (missing `score_format.dart`; `The getter 'scoreText' isn't defined for the type 'Hud'`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/score_format_test.dart test/game/hud_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/core/score_format.dart` with this complete content:

```dart
/// Formats a non-negative score with comma thousands separators ("14,820").
String formatScore(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final fromEnd = digits.length - i;
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/game/hud.dart` with:

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/text.dart';

import '../core/game_rules.dart';
import '../core/score_format.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// In-game HUD (spec §4.3): "SCORE" label + comma-grouped score top-left,
/// lives top-right as three 14px dots (filled ink = alive, hairline ring =
/// lost). Sits under the blade (priority 90 < 100).
class Hud extends PositionComponent with HasGameReference<AlaifGame> {
  Hud() : super(priority: 90);

  static const dotRadius = 7.0; // 14px dots
  static const dotGap = 24.0;

  static final TextPaint _labelPaint = TextPaint(style: AlaifType.label);
  static final TextPaint _scorePaint = TextPaint(style: AlaifType.scoreHud);

  String get scoreText => formatScore(game.scoreState.score);

  /// Dot [index] (0..2, left to right) is filled while that life remains.
  bool dotFilled(int index) => index < game.rules.lives;

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
    // Score block, top-left. The GameWidget is already inside a SafeArea.
    _labelPaint.render(
      canvas,
      'SCORE',
      Vector2(AlaifSpacing.xl, AlaifSpacing.lg),
    );
    _scorePaint.render(
      canvas,
      scoreText,
      Vector2(AlaifSpacing.xl, AlaifSpacing.lg + 18),
    );

    // Lives dots, top-right.
    final cy = AlaifSpacing.lg + 14;
    for (var i = 0; i < GameRules.startingLives; i++) {
      final cx = size.x -
          AlaifSpacing.xl -
          (GameRules.startingLives - 1 - i) * dotGap;
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

- [ ] Run the two test files, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/core/score_format_test.dart test/game/hud_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite (`blade_trail_test.dart` asserts a `Hud` is installed — the class name is unchanged, so it stays green): `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/core/score_format.dart app/lib/game/hud.dart app/test/core/score_format_test.dart app/test/game/hud_test.dart && git commit -m "feat(game): Ink & Paper HUD with score block and lives dots"
```

---

## Task 13: `HapticsService` + game wiring

Thin wrapper over Flutter's built-in `HapticFeedback` (no new dependency): light impact on slice, heavy impact on bomb and on a missed letter, all behind a toggleable `enabled` flag (settings wire it in Task 16).

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/services/haptics_service.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/services/haptics_service_test.dart`, `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` (extend)

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/services/haptics_service_test.dart`:

```dart
import 'package:alaif/services/haptics_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('slice fires a light impact', () {
    HapticsService().onSlice();
    expect(calls, hasLength(1));
    expect(calls.single.method, 'HapticFeedback.vibrate');
    expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
  });

  test('bomb and miss fire heavy impacts', () {
    final service = HapticsService();
    service.onBomb();
    service.onMiss();
    expect(calls, hasLength(2));
    expect(calls[0].arguments, 'HapticFeedbackType.heavyImpact');
    expect(calls[1].arguments, 'HapticFeedbackType.heavyImpact');
  });

  test('disabled service stays silent', () {
    final service = HapticsService()..enabled = false;
    service.onSlice();
    service.onBomb();
    service.onMiss();
    expect(calls, isEmpty);
  });
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/services/haptics_service.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/haptics_service_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/services/haptics_service.dart` with this complete content:

```dart
import 'package:flutter/services.dart';

/// Game-event haptics via Flutter's built-in [HapticFeedback] (no plugin).
/// Light tap on a slice; heavy thud on a bomb or a missed letter.
/// [enabled] is driven by the persisted settings.
class HapticsService {
  bool enabled = true;

  void onSlice() {
    if (enabled) HapticFeedback.lightImpact();
  }

  void onBomb() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  void onMiss() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
```

- [ ] Wire it into `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. Add the import — old:

```dart
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
```

New:

```dart
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
import '../ui/design_tokens.dart';
```

Constructor/fields — old:

```dart
  AlaifGame({HighScoreStore? highScores, Random? random})
      : highScores = highScores ?? HighScoreStore(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;
```

New:

```dart
  AlaifGame({HighScoreStore? highScores, HapticsService? haptics, Random? random})
      : highScores = highScores ?? HighScoreStore(),
        haptics = haptics ?? HapticsService(),
        _random = random ?? Random();

  final GlyphAtlas atlas = GlyphAtlas();
  final ScoreState scoreState = ScoreState();
  final GameRules rules = GameRules();
  final HighScoreStore highScores;
  final HapticsService haptics;
```

Bomb branch of `trySlice` — old:

```dart
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        _checkGameOver();
      }
```

New:

```dart
      if (segmentHitsCircle(from, to, bomb.position, bomb.hitRadius)) {
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        _checkGameOver();
      }
```

`_sliceLetter` — old:

```dart
  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    letter.removeFromParent();
```

New:

```dart
  void _sliceLetter(LetterComponent letter) {
    scoreState.registerHit();
    haptics.onSlice();
    letter.removeFromParent();
```

Missed-letter branch in `update` — old:

```dart
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          rules.onLetterMissed();
          _checkGameOver();
        }
```

New:

```dart
        if (letter.entered && letter.position.y > size.y + 120) {
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
          _checkGameOver();
        }
```

- [ ] Add a wiring test to `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`. Add the import — old:

```dart
import 'package:alaif/game/sliced_halves.dart';
import 'package:flame/components.dart';
```

New:

```dart
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/haptics_service.dart';
import 'package:flame/components.dart';
```

Add this recording fake just above `void main() {`:

```dart
class RecordingHaptics extends HapticsService {
  final events = <String>[];
  @override
  void onSlice() => events.add('slice');
  @override
  void onBomb() => events.add('bomb');
  @override
  void onMiss() => events.add('miss');
}
```

Append this test inside `main()`:

```dart
  testWithGame<AlaifGame>('haptics fire on slice, bomb, and miss',
      () => AlaifGame(haptics: RecordingHaptics()), (game) async {
    final haptics = game.haptics as RecordingHaptics;
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    expect(haptics.events, ['slice']);

    game.add(BombComponent(
      motion: ArcMotion(
          start: Vector2(100, 300), velocity: Vector2.zero(), gravity: 0),
    ));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(200, 300));
    expect(haptics.events, ['slice', 'bomb']);

    final missed = staticLetter(game)..entered = true;
    game.add(missed);
    game.update(0);
    missed.position.y = game.size.y + 500;
    game.update(0);
    expect(haptics.events, ['slice', 'bomb', 'miss']);
  });
```

- [ ] Run both test files, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/haptics_service_test.dart test/game/alaif_game_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/services/haptics_service.dart app/lib/game/alaif_game.dart app/test/services/haptics_service_test.dart app/test/game/alaif_game_test.dart && git commit -m "feat(game): haptic feedback on slice, bomb, and miss"
```

---

## Task 14: `AudioService` (flame_audio) + slice SFX asset + game wiring

Add `flame_audio` (pin `^2.11.14` — that version requires `flame ^1.35.1`, exactly our flame, so nothing else upgrades). `AudioService` preloads and plays SFX with **every failure non-fatal and silent** (per the design decision: bomb/combo/miss files intentionally don't exist yet; the user drops in CC0 sounds later). The one real sound: copy `raw/splat.mp3` to `app/assets/audio/slice.mp3` and wire it to the slice event.

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/services/audio_service.dart`
- Create: `/Users/iammoo/code/alaif/app/assets/audio/slice.mp3` (copied binary)
- Modify: `/Users/iammoo/code/alaif/app/pubspec.yaml`
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/services/audio_service_test.dart`, `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` (extend)

**Steps:**

- [ ] Add the dependency and asset folder to `/Users/iammoo/code/alaif/app/pubspec.yaml`. Old:

```yaml
  cupertino_icons: ^1.0.8
  flame: ^1.35.1
  shared_preferences: ^2.5.5
```

New:

```yaml
  cupertino_icons: ^1.0.8
  flame: ^1.35.1
  flame_audio: ^2.11.14
  shared_preferences: ^2.5.5
```

Old (the fonts block added in Task 2):

```yaml
  uses-material-design: true

  fonts:
```

New:

```yaml
  uses-material-design: true

  assets:
    - assets/audio/

  fonts:
```

Then fetch and copy the SFX:

```bash
cd /Users/iammoo/code/alaif/app && flutter pub get
mkdir -p /Users/iammoo/code/alaif/app/assets/audio
cp /Users/iammoo/code/alaif/raw/splat.mp3 /Users/iammoo/code/alaif/app/assets/audio/slice.mp3
```

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/services/audio_service_test.dart`:

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
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/services/audio_service.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/audio_service_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/services/audio_service.dart` with this complete content:

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
  bool enabled = true;

  static const sliceSfx = 'slice.mp3'; // real, bundled
  static const bombSfx = 'bomb.mp3'; // stub — may be missing
  static const comboSfx = 'combo.mp3'; // stub — may be missing
  static const missSfx = 'miss.mp3'; // stub — may be missing

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
    try {
      unawaited(
        FlameAudio.play(sfx).then<void>((_) {}).catchError((_) {}),
      );
    } catch (_) {
      // Synchronous audio failures are equally non-fatal.
    }
  }

  void playSlice() => _play(sliceSfx);
  void playBomb() => _play(bombSfx);
  void playCombo() => _play(comboSfx);
  void playMiss() => _play(missSfx);
}
```

- [ ] Wire it into `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. Import — old:

```dart
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
```

New:

```dart
import '../services/audio_service.dart';
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
```

Constructor/fields — old:

```dart
  AlaifGame({HighScoreStore? highScores, HapticsService? haptics, Random? random})
      : highScores = highScores ?? HighScoreStore(),
        haptics = haptics ?? HapticsService(),
        _random = random ?? Random();
```

New:

```dart
  AlaifGame({
    HighScoreStore? highScores,
    AudioService? audio,
    HapticsService? haptics,
    Random? random,
  })  : highScores = highScores ?? HighScoreStore(),
        audio = audio ?? AudioService(),
        haptics = haptics ?? HapticsService(),
        _random = random ?? Random();
```

Old:

```dart
  final HighScoreStore highScores;
  final HapticsService haptics;
```

New:

```dart
  final HighScoreStore highScores;
  final AudioService audio;
  final HapticsService haptics;
```

Preload during load — old:

```dart
  Future<void> onLoad() async {
    await atlas.load();
    await add(PaperBackground());
```

New:

```dart
  Future<void> onLoad() async {
    await atlas.load();
    unawaited(audio.preload()); // fire-and-forget; failures are silent
    await add(PaperBackground());
```

Event hooks — old:

```dart
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
```

New:

```dart
        bomb.removeFromParent();
        rules.onBombSliced();
        haptics.onBomb();
        audio.playBomb();
```

Old:

```dart
    scoreState.registerHit();
    haptics.onSlice();
    letter.removeFromParent();
```

New:

```dart
    scoreState.registerHit();
    haptics.onSlice();
    audio.playSlice();
    letter.removeFromParent();
```

Old:

```dart
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
```

New:

```dart
          letter.removeFromParent();
          rules.onLetterMissed();
          haptics.onMiss();
          audio.playMiss();
```

Old (the combo branch of `endSwipe` from Task 11):

```dart
    add(ComboCallout(text: ComboCallout.comboText(hits)));
  }
```

New:

```dart
    add(ComboCallout(text: ComboCallout.comboText(hits)));
    audio.playCombo();
  }
```

- [ ] Add a wiring test to `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`. Import — old:

```dart
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/haptics_service.dart';
```

New:

```dart
import 'package:alaif/game/sliced_halves.dart';
import 'package:alaif/services/audio_service.dart';
import 'package:alaif/services/haptics_service.dart';
```

Add this fake next to `RecordingHaptics` (above `void main() {`):

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

Append this test inside `main()`:

```dart
  testWithGame<AlaifGame>('audio preloads and fires on slice and combo',
      () => AlaifGame(audio: RecordingAudio()), (game) async {
    final audio = game.audio as RecordingAudio;
    expect(audio.events, contains('preload'));

    game.startGame();
    game.add(staticLetter(game, x: 80));
    game.add(staticLetter(game, x: 180));
    game.add(staticLetter(game, x: 280));
    game.update(0);
    game.trySlice(Vector2(0, 300), Vector2(360, 300));
    game.endSwipe();

    expect(audio.events.where((e) => e == 'slice').length, 3);
    expect(audio.events, contains('combo'));
  });
```

- [ ] Run both test files, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/audio_service_test.dart test/game/alaif_game_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/pubspec.yaml app/pubspec.lock app/assets/audio/slice.mp3 app/lib/services/audio_service.dart app/lib/game/alaif_game.dart app/test/services/audio_service_test.dart app/test/game/alaif_game_test.dart && git commit -m "feat(game): non-fatal AudioService via flame_audio with real slice SFX"
```

---

## Task 15: `SettingsStore` (sound/music/haptics persistence)

Persisted toggles via `shared_preferences`, mirroring `HighScoreStore`'s style: all default **true**, and corrupt/missing values silently fall back to defaults. (File path per the design's file map: `services/settings.dart`.)

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/services/settings.dart`
- Test: `/Users/iammoo/code/alaif/app/test/services/settings_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/services/settings_test.dart`:

```dart
import 'package:alaif/services/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('everything defaults to enabled', () async {
    final store = SettingsStore();
    expect(await store.soundEnabled(), isTrue);
    expect(await store.musicEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isTrue);
  });

  test('set/read round-trips each flag independently', () async {
    final store = SettingsStore();
    await store.setSoundEnabled(false);
    await store.setHapticsEnabled(false);
    expect(await store.soundEnabled(), isFalse);
    expect(await store.musicEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isFalse);

    await store.setSoundEnabled(true);
    expect(await store.soundEnabled(), isTrue);
  });

  test('corrupt stored values fall back to defaults', () async {
    SharedPreferences.setMockInitialValues({
      'settings.sound': 'definitely-not-a-bool',
      'settings.haptics': 42,
    });
    final store = SettingsStore();
    expect(await store.soundEnabled(), isTrue);
    expect(await store.hapticsEnabled(), isTrue);
  });
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/services/settings.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/settings_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/services/settings.dart` with this complete content:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted player settings. Defaults are all ON; corrupt or missing
/// preferences silently fall back to defaults — settings must never crash
/// or block the game.
class SettingsStore {
  static const _soundKey = 'settings.sound';
  static const _musicKey = 'settings.music';
  static const _hapticsKey = 'settings.haptics';

  Future<bool> soundEnabled() => _readBool(_soundKey);
  Future<void> setSoundEnabled(bool value) => _writeBool(_soundKey, value);

  Future<bool> musicEnabled() => _readBool(_musicKey);
  Future<void> setMusicEnabled(bool value) => _writeBool(_musicKey, value);

  Future<bool> hapticsEnabled() => _readBool(_hapticsKey);
  Future<void> setHapticsEnabled(bool value) => _writeBool(_hapticsKey, value);

  Future<bool> _readBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? true;
    } catch (_) {
      return true; // corrupt value or unavailable prefs → default ON
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {
      // A lost setting must never crash the game.
    }
  }
}
```

- [ ] Run the settings tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/services/settings_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/services/settings.dart app/test/services/settings_test.dart && git commit -m "feat(services): persisted sound/music/haptics settings with safe defaults"
```

---

## Task 16: Game plumbing — apply settings, new overlay stubs, navigation methods

`AlaifGame` learns the M4 moves: it owns a `SettingsStore`, applies persisted flags to audio/haptics on load, registers the two new overlay names (`howTo`, `settings`) in its guarded test-stub loop, and gains navigation methods the overlays call: `openHowTo`/`closeHowTo`, `openSettings(from:)`/`closeSettings` (returns to wherever it was opened from), and `quitToMenu` (from pause **or** game over).

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`
- Test: `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart` (extend)

**Steps:**

- [ ] Append these tests inside `main()` of `/Users/iammoo/code/alaif/app/test/game/alaif_game_test.dart`:

```dart
  testWithGame<AlaifGame>('persisted settings flags reach audio and haptics',
      () {
    SharedPreferences.setMockInitialValues({
      'settings.sound': false,
      'settings.haptics': false,
    });
    return AlaifGame();
  }, (game) async {
    expect(game.audio.enabled, isFalse);
    expect(game.haptics.enabled, isFalse);
  });

  testWithGame<AlaifGame>('how-to opens from the menu and returns to it',
      AlaifGame.new, (game) async {
    expect(game.overlays.isActive('menu'), isTrue);
    game.openHowTo();
    expect(game.overlays.isActive('howTo'), isTrue);
    expect(game.overlays.isActive('menu'), isFalse);
    game.closeHowTo();
    expect(game.overlays.isActive('menu'), isTrue);
    expect(game.overlays.isActive('howTo'), isFalse);
  });

  testWithGame<AlaifGame>('settings remembers where it was opened from',
      AlaifGame.new, (game) async {
    game.openSettings(from: 'menu');
    expect(game.overlays.isActive('settings'), isTrue);
    expect(game.overlays.isActive('menu'), isFalse);
    game.closeSettings();
    expect(game.overlays.isActive('menu'), isTrue);

    game.startGame();
    game.pauseGame();
    game.openSettings(from: 'paused');
    expect(game.overlays.isActive('settings'), isTrue);
    expect(game.overlays.isActive('paused'), isFalse);
    game.closeSettings();
    expect(game.overlays.isActive('paused'), isTrue);
  });

  testWithGame<AlaifGame>('quitToMenu clears the board and returns to menu',
      AlaifGame.new, (game) async {
    game.startGame();
    game.add(staticLetter(game));
    game.update(0);
    game.pauseGame();

    game.quitToMenu();
    expect(game.paused, isFalse); // engine resumed so the menu animates
    expect(game.isPlaying, isFalse);
    expect(game.children.whereType<LetterComponent>(), isEmpty);
    expect(game.overlays.isActive('menu'), isTrue);
    expect(game.overlays.isActive('paused'), isFalse);
    expect(game.overlays.isActive('controls'), isFalse);
  });
```

- [ ] Run it, expect compile failure (`The method 'openHowTo' isn't defined`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart
```

- [ ] Edit `/Users/iammoo/code/alaif/app/lib/game/alaif_game.dart`. Import — old:

```dart
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
```

New:

```dart
import '../services/haptics_service.dart';
import '../services/high_score_store.dart';
import '../services/settings.dart';
```

Constructor/fields — old:

```dart
  AlaifGame({
    HighScoreStore? highScores,
    AudioService? audio,
    HapticsService? haptics,
    Random? random,
  })  : highScores = highScores ?? HighScoreStore(),
        audio = audio ?? AudioService(),
        haptics = haptics ?? HapticsService(),
        _random = random ?? Random();
```

New:

```dart
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
```

Old:

```dart
  final HighScoreStore highScores;
  final AudioService audio;
  final HapticsService haptics;
```

New:

```dart
  final HighScoreStore highScores;
  final AudioService audio;
  final HapticsService haptics;
  final SettingsStore settings;
  String _settingsReturnOverlay = 'menu';
```

`onLoad` — old:

```dart
  Future<void> onLoad() async {
    await atlas.load();
    unawaited(audio.preload()); // fire-and-forget; failures are silent
    await add(PaperBackground());
    // Register fallback builders so overlays.add/isActive work in test
    // environments where no GameWidget overlay entries are provided.
    for (final name in const ['menu', 'gameOver', 'paused', 'controls']) {
      if (!overlays.registeredOverlays.contains(name)) {
        overlays.addEntry(name, (_, _) => const SizedBox.shrink());
      }
    }
    overlays.add('menu');
  }
```

New:

```dart
  Future<void> onLoad() async {
    await atlas.load();
    audio.enabled = await settings.soundEnabled();
    haptics.enabled = await settings.hapticsEnabled();
    unawaited(audio.preload()); // fire-and-forget; failures are silent
    await add(PaperBackground());
    // Register fallback builders so overlays.add/isActive work in test
    // environments where no GameWidget overlay entries are provided.
    for (final name in const [
      'menu',
      'gameOver',
      'paused',
      'controls',
      'howTo',
      'settings',
    ]) {
      if (!overlays.registeredOverlays.contains(name)) {
        overlays.addEntry(name, (_, _) => const SizedBox.shrink());
      }
    }
    overlays.add('menu');
  }
```

Add the navigation methods directly after `resumeFromPause()` — old:

```dart
  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
  }
```

New:

```dart
  void resumeFromPause() {
    overlays.remove('paused');
    overlays.add('controls');
    resumeEngine();
  }

  void openHowTo() {
    overlays.remove('menu');
    overlays.add('howTo');
  }

  void closeHowTo() {
    overlays.remove('howTo');
    overlays.add('menu');
  }

  /// [from] is the overlay to return to on [closeSettings]: 'menu' or 'paused'.
  void openSettings({required String from}) {
    _settingsReturnOverlay = from;
    overlays.remove(from);
    overlays.add('settings');
  }

  void closeSettings() {
    overlays.remove('settings');
    overlays.add(_settingsReturnOverlay);
  }

  /// Abandon the current run (from pause or game over) and show the menu.
  void quitToMenu() {
    _playing = false;
    if (paused) resumeEngine();
    children
        .where((c) =>
            c is LetterComponent ||
            c is BombComponent ||
            c is SlicedHalf ||
            c is Spawner)
        .toList()
        .forEach((c) => c.removeFromParent());
    overlays.remove('paused');
    overlays.remove('gameOver');
    overlays.remove('controls');
    overlays.add('menu');
  }
```

- [ ] Run the game tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/game/alaif_game_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/game/alaif_game.dart app/test/game/alaif_game_test.dart && git commit -m "feat(game): settings application and overlay navigation plumbing"
```

---

## Task 17: Menu overlay rebuild (spec §4.1)

Seal stamp + tracked label + Arabic accent on top; italic `Alaif` wordmark with a seal rule and tagline; BEST row; full-width ink Play button; "How to play" / "Sound" text links; faint giant `ل` watermark bottom-right. All styling flows from `buildAlaifTheme()` + `AlaifType` consts.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/menu_overlay.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart` (update the menu test)

**Steps:**

- [ ] Update the menu test in `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart`. Imports — old:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/game_over_overlay.dart';
import 'package:alaif/ui/menu_overlay.dart';
import 'package:alaif/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
```

New:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/game_over_overlay.dart';
import 'package:alaif/ui/menu_overlay.dart';
import 'package:alaif/ui/pause_overlay.dart';
import 'package:flutter/material.dart';
```

Menu test — old:

```dart
  testWidgets('menu shows title, best score, and Play', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MenuOverlay(game: AlaifGame())));
    await tester.pumpAndSettle();
    expect(find.text('Alaif'), findsOneWidget);
    expect(find.text('Best: 70'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
```

New:

```dart
  testWidgets('menu shows wordmark, best score, Play, and links', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: MenuOverlay(game: AlaifGame())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Alaif'), findsOneWidget);
    expect(find.text('A SLICING GAME'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
  });
```

- [ ] Run it, expect failure (`Expected: exactly one matching candidate ... 'A SLICING GAME' ... Actual: ... means none were found`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/ui/menu_overlay.dart` with:

```dart
import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Main menu (spec §4.1): seal stamp + label + Arabic accent, italic
/// wordmark over a seal rule, BEST score, ink Play button, and two text
/// links. A faint giant lam watermarks the bottom-right of the paper.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          right: -30,
          bottom: -60,
          child: IgnorePointer(
            child: Text(
              'ل',
              style: TextStyle(
                fontFamily: AlaifFonts.arabic,
                fontSize: 320,
                color: Color(0x0D1B1712), // 5% ink watermark
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlaifSpacing.screenPad,
            vertical: AlaifSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 14, height: 14, color: AlaifColors.seal),
                  const SizedBox(width: AlaifSpacing.sm),
                  const Text('A SLICING GAME', style: AlaifType.label),
                  const Spacer(),
                  const Text('الألِف', style: AlaifType.titleArabic),
                ],
              ),
              const Spacer(),
              const Text('Alaif', style: AlaifType.titleDisplay),
              const SizedBox(height: AlaifSpacing.md),
              Container(width: 64, height: 2, color: AlaifColors.seal),
              const SizedBox(height: AlaifSpacing.lg),
              const SizedBox(
                width: 230,
                child: Text(
                  'Swipe to slice the falling letters.',
                  style: AlaifType.bodyMuted,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('BEST', style: AlaifType.label),
                  const Spacer(),
                  FutureBuilder<int>(
                    future: game.highScores.read(),
                    builder: (context, snapshot) => Text(
                      formatScore(snapshot.data ?? 0),
                      style: AlaifType.scoreHud.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AlaifSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: game.startGame,
                  child: const Text('Play'),
                ),
              ),
              const SizedBox(height: AlaifSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: game.openHowTo,
                    child: const Text('How to play'),
                  ),
                  const SizedBox(width: AlaifSpacing.lg),
                  TextButton(
                    onPressed: () => game.openSettings(from: 'menu'),
                    child: const Text('Sound'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] Run the overlay tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/menu_overlay.dart app/test/ui/overlays_test.dart && git commit -m "feat(ui): Ink & Paper main menu overlay"
```

---

## Task 18: How-to-play overlay (new, spec §4.2)

Three rows — swipe stroke, combo dots, bomb — each a 56px hairline icon tile + italic subheading + muted body, with a primary "Got it" pinned to the bottom. Icons are tiny `CustomPainter`s (no assets). Registered in `main.dart`'s overlay map as `howTo` (the in-game stub from Task 16 already covers tests).

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/ui/how_to_overlay.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/main.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/how_to_overlay_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/ui/how_to_overlay_test.dart`:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/how_to_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('how-to shows the three lessons and Got it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: HowToOverlay(game: AlaifGame())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('Swipe to slice'), findsOneWidget);
    expect(find.text('Chain combos'), findsOneWidget);
    expect(find.text('Avoid the bombs'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/ui/how_to_overlay.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/how_to_overlay_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/ui/how_to_overlay.dart` with this complete content:

```dart
import 'package:flutter/material.dart';

import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// How to play (spec §4.2): three icon-tile rows + a bottom-pinned primary.
class HowToOverlay extends StatelessWidget {
  const HowToOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AlaifColors.paper,
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
        vertical: AlaifSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 14, height: 14, color: AlaifColors.seal),
          const SizedBox(height: AlaifSpacing.lg),
          const Text('How to play', style: AlaifType.heading),
          const SizedBox(height: AlaifSpacing.xxl),
          const _HowToRow(
            painter: _SwipeStrokePainter(),
            title: 'Swipe to slice',
            body: 'Drag a quick stroke through a letter to cut it in two.',
          ),
          const SizedBox(height: AlaifSpacing.xl),
          const _HowToRow(
            painter: _ComboDotsPainter(),
            title: 'Chain combos',
            body: 'Cut three or more in one swipe for bonus gold dust.',
          ),
          const SizedBox(height: AlaifSpacing.xl),
          const _HowToRow(
            painter: _BombIconPainter(),
            title: 'Avoid the bombs',
            body: 'Slicing a seal-ringed bomb costs you a life.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: game.closeHowTo,
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToRow extends StatelessWidget {
  const _HowToRow({
    required this.painter,
    required this.title,
    required this.body,
  });

  final CustomPainter painter;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: AlaifColors.hairline),
            borderRadius: BorderRadius.circular(AlaifRadii.sm),
          ),
          child: CustomPaint(painter: painter),
        ),
        const SizedBox(width: AlaifSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AlaifType.subheading),
              const SizedBox(height: AlaifSpacing.xs),
              Text(body, style: AlaifType.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}

/// Curved ink stroke with an arrowhead.
class _SwipeStrokePainter extends CustomPainter {
  const _SwipeStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlaifColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.15,
        size.width * 0.8,
        size.height * 0.3,
      );
    canvas.drawPath(path, paint);
    // Arrowhead at the stroke's end.
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.66, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.72, size.height * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three ink dots with gold-dust specks.
class _ComboDotsPainter extends CustomPainter {
  const _ComboDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = AlaifColors.ink;
    final dust = Paint()..color = AlaifColors.goldDust;
    final cy = size.height * 0.55;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.25 + 0.25 * i), cy),
        4,
        ink,
      );
    }
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.28), 1.5, dust);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.22), 2, dust);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.34), 1.5, dust);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini ink bomb with the seal ring and a gold spark.
class _BombIconPainter extends CustomPainter {
  const _BombIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    const radius = 13.0;
    canvas.drawCircle(center, radius, Paint()..color = AlaifColors.ink);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AlaifColors.seal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center.translate(radius * 0.8, -radius * 1.15),
      2,
      Paint()..color = AlaifColors.goldDust,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] Register the overlay in `/Users/iammoo/code/alaif/app/lib/main.dart`. Imports — old:

```dart
import 'ui/game_over_overlay.dart';
import 'ui/menu_overlay.dart';
```

New:

```dart
import 'ui/game_over_overlay.dart';
import 'ui/how_to_overlay.dart';
import 'ui/menu_overlay.dart';
```

Overlay map — old:

```dart
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
              'controls': (context, game) => ControlsOverlay(game: game),
            },
```

New:

```dart
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
              'controls': (context, game) => ControlsOverlay(game: game),
              'howTo': (context, game) => HowToOverlay(game: game),
            },
```

- [ ] Run the how-to test, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/how_to_overlay_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/how_to_overlay.dart app/lib/main.dart app/test/ui/how_to_overlay_test.dart && git commit -m "feat(ui): how-to-play overlay with painted lesson icons"
```

---

## Task 19: Pause overlay rebuild (spec §4.4)

Paper scrim (0.78) over the frozen game, centered `PAUSED` label + big current score, primary Resume, ghost Restart/Settings row, and a Quit-to-menu text link.

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/pause_overlay.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart` (update the pause test)

**Steps:**

- [ ] Update the pause test in `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart`. Old:

```dart
  testWidgets('pause overlay shows Resume', (tester) async {
    await tester
        .pumpWidget(MaterialApp(home: PauseOverlay(game: AlaifGame())));
    expect(find.text('Resume'), findsOneWidget);
  });
```

New:

```dart
  testWidgets('pause overlay shows score and all four actions', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: PauseOverlay(game: AlaifGame())),
    ));
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('CURRENT SCORE'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Quit to menu'), findsOneWidget);
  });
```

- [ ] Run it, expect failure (`'PAUSED'` not found):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/ui/pause_overlay.dart` with:

```dart
import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Pause (spec §4.4): paper scrim over the frozen game, current score,
/// Resume primary, Restart/Settings ghosts, Quit-to-menu link.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AlaifColors.scrim,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PAUSED',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.lg),
          Text(
            formatScore(game.scoreState.score),
            style: AlaifType.scoreLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.sm),
          const Text(
            'CURRENT SCORE',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xxl),
          ElevatedButton(
            onPressed: game.resumeFromPause,
            child: const Text('Resume'),
          ),
          const SizedBox(height: AlaifSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: game.startGame,
                  child: const Text('Restart'),
                ),
              ),
              const SizedBox(width: AlaifSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => game.openSettings(from: 'paused'),
                  child: const Text('Settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AlaifSpacing.md),
          TextButton(
            onPressed: game.quitToMenu,
            child: const Text('Quit to menu'),
          ),
        ],
      ),
    );
  }
}
```

(Restart works straight from pause: `startGame()` already resumes the engine and removes the `paused` overlay.)

- [ ] Run the overlay tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/pause_overlay.dart app/test/ui/overlays_test.dart && git commit -m "feat(ui): Ink & Paper pause overlay with restart, settings, and quit"
```

---

## Task 20: Game-over overlay rebuild (spec §4.5)

Bottom-anchored: seal italic *"The blade rests"*, `FINAL SCORE` label + `scoreLarge` number, two hairline-split stat columns (**BEST** from the high-score store, **BEST COMBO** from this run), primary "Play again", ghost "Main menu".

**Files:**
- Modify: `/Users/iammoo/code/alaif/app/lib/ui/game_over_overlay.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart` (update the game-over test)

**Steps:**

- [ ] Update the game-over test in `/Users/iammoo/code/alaif/app/test/ui/overlays_test.dart`. Old:

```dart
  testWidgets('game over shows final score and Play Again', (tester) async {
    final game = AlaifGame();
    await tester
        .pumpWidget(MaterialApp(home: GameOverOverlay(game: game)));
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Play Again'), findsOneWidget);
  });
```

New:

```dart
  testWidgets('game over shows final score, stats, and both actions',
      (tester) async {
    final game = AlaifGame();
    game.scoreState.registerHit(); // final score 10 ≠ best combo 0
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: GameOverOverlay(game: game)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('The blade rests'), findsOneWidget);
    expect(find.text('FINAL SCORE'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('70'), findsOneWidget); // from mocked prefs
    expect(find.text('BEST COMBO'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // best combo this run
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Main menu'), findsOneWidget);
  });
```

- [ ] Run it, expect failure (`'The blade rests'` not found):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

- [ ] Replace the entire contents of `/Users/iammoo/code/alaif/app/lib/ui/game_over_overlay.dart` with:

```dart
import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Game over (spec §4.5): bottom-anchored "The blade rests", final score,
/// BEST / BEST COMBO stat columns split by a hairline, Play again + Main menu.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
        vertical: AlaifSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Text(
            'The blade rests',
            style: AlaifType.combo,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.lg),
          const Text(
            'FINAL SCORE',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xs),
          Text(
            formatScore(game.scoreState.score),
            style: AlaifType.scoreLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xl),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('BEST', style: AlaifType.label),
                      const SizedBox(height: AlaifSpacing.xs),
                      FutureBuilder<int>(
                        future: game.highScores.read(),
                        builder: (context, snapshot) => Text(
                          formatScore(snapshot.data ?? 0),
                          style: AlaifType.scoreHud.copyWith(fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(color: AlaifColors.hairline),
                Expanded(
                  child: Column(
                    children: [
                      const Text('BEST COMBO', style: AlaifType.label),
                      const SizedBox(height: AlaifSpacing.xs),
                      Text(
                        formatScore(game.scoreState.bestCombo),
                        style: AlaifType.scoreHud.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlaifSpacing.xxl),
          ElevatedButton(
            onPressed: game.startGame,
            child: const Text('Play again'),
          ),
          const SizedBox(height: AlaifSpacing.md),
          OutlinedButton(
            onPressed: game.quitToMenu,
            child: const Text('Main menu'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] Run the overlay tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/overlays_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/game_over_overlay.dart app/test/ui/overlays_test.dart && git commit -m "feat(ui): Ink & Paper game-over overlay with best-combo stat"
```

---

## Task 21: Settings overlay (new, spec §4.6)

Heading + seal rule; hairline-divided rows with ink-pill switches for **Sound effects**, **Music**, **Haptics** (each with a muted sub-label); a hairline card showing **Best score**; footer caption `Alaif · v1.0 · made offline`; primary **Done**. Toggles persist via `SettingsStore` AND apply live to `game.audio.enabled` / `game.haptics.enabled` (music is persisted-only — there is no music player yet). Registered in `main.dart` as `settings`.

**Files:**
- Create: `/Users/iammoo/code/alaif/app/lib/ui/settings_overlay.dart`
- Modify: `/Users/iammoo/code/alaif/app/lib/main.dart`
- Test: `/Users/iammoo/code/alaif/app/test/ui/settings_overlay_test.dart`

**Steps:**

- [ ] Write the failing test at `/Users/iammoo/code/alaif/app/test/ui/settings_overlay_test.dart`:

```dart
import 'package:alaif/game/alaif_game.dart';
import 'package:alaif/ui/alaif_theme.dart';
import 'package:alaif/ui/settings_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<AlaifGame> pumpSettings(WidgetTester tester) async {
    final game = AlaifGame();
    await tester.pumpWidget(MaterialApp(
      theme: buildAlaifTheme(),
      home: Scaffold(body: SettingsOverlay(game: game)),
    ));
    await tester.pumpAndSettle();
    return game;
  }

  testWidgets('settings shows all rows, best score, footer, and Done',
      (tester) async {
    SharedPreferences.setMockInitialValues({'highScore': 70});
    await pumpSettings(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Haptics'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));
    expect(find.text('Best score'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(find.text('Alaif · v1.0 · made offline'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('switches default to on', (tester) async {
    await pumpSettings(tester);
    for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(s.value, isTrue);
    }
  });

  testWidgets('toggling sound persists and silences the audio service',
      (tester) async {
    final game = await pumpSettings(tester);
    expect(game.audio.enabled, isTrue);

    await tester.tap(find.byType(Switch).first); // rows render in order: sound first
    await tester.pumpAndSettle();

    expect(game.audio.enabled, isFalse);
    expect(await game.settings.soundEnabled(), isFalse);
  });

  testWidgets('toggling haptics persists and disables the haptics service',
      (tester) async {
    final game = await pumpSettings(tester);

    await tester.tap(find.byType(Switch).at(2)); // third row: haptics
    await tester.pumpAndSettle();

    expect(game.haptics.enabled, isFalse);
    expect(await game.settings.hapticsEnabled(), isFalse);
  });
}
```

- [ ] Run it, expect compile failure (missing `package:alaif/ui/settings_overlay.dart`):

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/settings_overlay_test.dart
```

- [ ] Create `/Users/iammoo/code/alaif/app/lib/ui/settings_overlay.dart` with this complete content:

```dart
import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Settings (spec §4.6): switch rows for sound/music/haptics, a best-score
/// card, an offline footer, and a primary Done that returns to wherever
/// settings was opened from.
class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  bool _sound = true;
  bool _music = true;
  bool _haptics = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sound = await widget.game.settings.soundEnabled();
    final music = await widget.game.settings.musicEnabled();
    final haptics = await widget.game.settings.hapticsEnabled();
    if (!mounted) return;
    setState(() {
      _sound = sound;
      _music = music;
      _haptics = haptics;
    });
  }

  Widget _row({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AlaifSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AlaifType.body),
                Text(subtitle, style: AlaifType.caption),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Container(
      color: AlaifColors.paper,
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
        vertical: AlaifSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Settings', style: AlaifType.heading),
          const SizedBox(height: AlaifSpacing.md),
          Container(width: 64, height: 2, color: AlaifColors.seal),
          const SizedBox(height: AlaifSpacing.xl),
          _row(
            title: 'Sound effects',
            subtitle: 'Slices, bombs, and combos',
            value: _sound,
            onChanged: (v) {
              setState(() => _sound = v);
              game.settings.setSoundEnabled(v);
              game.audio.enabled = v;
            },
          ),
          const Divider(),
          _row(
            title: 'Music',
            subtitle: 'Background music',
            value: _music,
            onChanged: (v) {
              setState(() => _music = v);
              game.settings.setMusicEnabled(v); // stored; no music player yet
            },
          ),
          const Divider(),
          _row(
            title: 'Haptics',
            subtitle: 'Vibration on slice and miss',
            value: _haptics,
            onChanged: (v) {
              setState(() => _haptics = v);
              game.settings.setHapticsEnabled(v);
              game.haptics.enabled = v;
            },
          ),
          const SizedBox(height: AlaifSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AlaifSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AlaifColors.hairline),
              borderRadius: BorderRadius.circular(AlaifRadii.sm),
            ),
            child: Row(
              children: [
                const Text('Best score', style: AlaifType.bodyMuted),
                const Spacer(),
                FutureBuilder<int>(
                  future: game.highScores.read(),
                  builder: (context, snapshot) => Text(
                    formatScore(snapshot.data ?? 0),
                    style: AlaifType.scoreHud.copyWith(fontSize: 24),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Text(
            'Alaif · v1.0 · made offline',
            style: AlaifType.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.lg),
          ElevatedButton(
            onPressed: game.closeSettings,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] Register the overlay in `/Users/iammoo/code/alaif/app/lib/main.dart`. Imports — old:

```dart
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
```

New:

```dart
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/settings_overlay.dart';
```

Overlay map — old:

```dart
              'howTo': (context, game) => HowToOverlay(game: game),
            },
```

New:

```dart
              'howTo': (context, game) => HowToOverlay(game: game),
              'settings': (context, game) => SettingsOverlay(game: game),
            },
```

- [ ] Run the settings tests, expect pass:

```bash
cd /Users/iammoo/code/alaif/app && flutter test test/ui/settings_overlay_test.dart
```

Expected: `All tests passed!`

- [ ] Run the full suite: `cd /Users/iammoo/code/alaif/app && flutter test` → `All tests passed!`
- [ ] Commit:

```bash
cd /Users/iammoo/code/alaif && git add app/lib/ui/settings_overlay.dart app/lib/main.dart app/test/ui/settings_overlay_test.dart && git commit -m "feat(ui): settings overlay with persisted sound/music/haptics toggles"
```

---

## Task 22: Final verification — full test + analyze pass

**Files:**
- No new files. Fix-forward only if checks fail.

**Steps:**

- [ ] Run the complete test suite and confirm every test passes:

```bash
cd /Users/iammoo/code/alaif/app && flutter test
```

Expected: `All tests passed!` (the original 54 plus all tests added by Tasks 1–21).

- [ ] Run the analyzer and confirm zero issues:

```bash
cd /Users/iammoo/code/alaif/app && flutter analyze
```

Expected: `No issues found!`

- [ ] If either command reports problems, fix them minimally (style nits, missed imports, deprecations such as `withOpacity` → `withValues`), re-run both commands until clean, and only then proceed.
- [ ] Sanity-check git state — only intended files changed:

```bash
cd /Users/iammoo/code/alaif && git status --short
```

Expected: empty output (everything committed by Tasks 1–21).

- [ ] If fixes were needed, commit them:

```bash
cd /Users/iammoo/code/alaif && git add -A app && git commit -m "chore: final lint and test cleanup for Ink & Paper M3+M4"
```

(Skip this commit if the working tree was already clean.)

---

## Out of scope (deliberately)

- **M5 store prep** (app icon §5, screenshots) — planned separately after device testing.
- **Real bomb/combo/miss SFX** — `AudioService` stubs them; the user drops in CC0 files at `app/assets/audio/{bomb,combo,miss}.mp3` later with zero code changes.
- **Music playback** — the Music toggle persists state only; no player exists yet.
- **Blade blur glow** (spec §7.4 optional) — solid ink reads well on paper; skipped for perf simplicity.
- **On-device performance profiling** — `AlaifMotion` values are starting points; tuning happens on hardware after this plan ships.

