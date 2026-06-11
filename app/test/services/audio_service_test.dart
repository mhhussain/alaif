import 'dart:io';

import 'package:alaif/services/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // flame_audio's Bgm constructs an AudioPlayer, which fires an async
  // platform-channel call to initialize the global audioplayers plugin.
  // With no plugin registered in tests this throws a MissingPluginException
  // on an unrelated async gap. Stub both audioplayers channels so
  // FlameAudio.bgm construction/playback never throws.
  for (final channel in const [
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
  ]) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      MethodChannel(channel),
      (call) async => null,
    );
  }

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

  test(
      'musicEnabled = false skips playBackgroundMusic and resumeBackgroundMusic',
      () async {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls)
      ..musicEnabled = false;

    await service.playBackgroundMusic();
    service.resumeBackgroundMusic();

    expect(calls, isEmpty);
  });

  test('pauseBackgroundMusic runs even when music is disabled', () {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls)
      ..musicEnabled = false;

    service.pauseBackgroundMusic();

    expect(calls, ['pause']);
  });

  test('a second playBackgroundMusic call is a no-op (no layered tracks)',
      () async {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls);

    await service.playBackgroundMusic();
    await service.playBackgroundMusic();

    expect(calls, ['play']);
  });

  test('setMusicEnabled(false) stops music; setMusicEnabled(true) plays it again',
      () async {
    final calls = <String>[];
    final service = BgmRecordingAudioService(calls: calls);

    await service.playBackgroundMusic();
    expect(calls, ['play']);

    await service.setMusicEnabled(false);
    expect(calls, ['play', 'stop']);
    expect(service.musicEnabled, isFalse);

    await service.setMusicEnabled(true);
    expect(calls, ['play', 'stop', 'play']);
    expect(service.musicEnabled, isTrue);
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

  @override
  void stopBackgroundMusicInternal() => calls.add('stop');
}
