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
