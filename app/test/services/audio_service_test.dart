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
