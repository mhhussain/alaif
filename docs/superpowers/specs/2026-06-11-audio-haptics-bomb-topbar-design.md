# Background Music, Haptics, Bomb Effect, Topbar Fix

- type: spec
- created: 2026-06-11
- status: approved

## Context

Four small, independent gameplay polish fixes:

1. `app/assets/audio/background.mp3` exists but isn't wired into playback.
2. Haptic feedback code (`lib/services/haptics_service.dart`) is fully implemented but doesn't fire on Android — `VIBRATE` permission is missing from `AndroidManifest.xml`.
3. Bombs disappear silently on hit (`bomb_component.dart` / `alaif_game.dart` `trySlice()`); only a sound plays.
4. The pause button (`lib/ui/controls_overlay.dart`, top-right `Align`/`SafeArea`, 8px padding) visually overlaps the lives dots drawn by the HUD (`lib/game/hud.dart`, top-right, ~32px margin).

## Design

### 1. Background music loop
- `AudioService` (`lib/services/audio_service.dart`) gains:
  - `playBackgroundMusic()` — `FlameAudio.bgm.play('background.mp3', volume: ...)`, looping.
  - `pauseBackgroundMusic()` / `resumeBackgroundMusic()`.
- Music starts once on game load (after first frame / on game mount).
- Hooked into existing `pauseGame()` / `resumeGame()` in `alaif_game.dart` so music pauses with the game.
- Existing `lifecycleStateChange` (line ~317) also pauses/resumes music alongside game pause for app backgrounding.

### 2. Enable haptics (Android)
- Add `<uses-permission android:name="android.permission.VIBRATE" />` to `app/android/app/src/main/AndroidManifest.xml`.
- No Dart code changes needed — `HapticFeedback` calls in `haptics_service.dart` are already wired into slice/bomb/miss events.

### 3. Bomb visual effect
- In `trySlice()` (`alaif_game.dart`, ~line 129-137), before `bomb.removeFromParent()`, spawn an ink-burst-style effect at the bomb's position — reusing the same component pattern used for letter-slice ink bursts (~line 165-167), but larger and darker to read as an "ink splat" rather than a clean slice.
- No new asset required; reuse existing burst component with adjusted size/color/opacity params.

### 4. Topbar overlap fix
- In `controls_overlay.dart`, reposition the pause button so it aligns vertically with the lives-dots row (HUD top-right, ~32px from top + safe area) instead of hugging the corner at 8px padding.
- Adjust padding/alignment only — no structural changes to HUD canvas rendering.

## Testing

- Manual: run app, confirm music starts on load, pauses on pause/resume and app backgrounding.
- Manual: confirm haptic buzz on slice/bomb/miss on a physical Android device.
- Manual: visually confirm bomb ink-splat appears on bomb hit.
- Manual: visually confirm pause button no longer overlaps lives dots across device sizes (use SafeArea variations if possible).

## Out of scope

- New audio/visual assets beyond what exists.
- iOS haptics (no permission needed; assumed already working via Flutter's native API).
- Broader HUD redesign.
