import 'dart:math';

/// Linear ramp over [rampSeconds] of play time.
class DifficultyCurve {
  static const startInterval = 1.2;
  static const minInterval = 0.4;
  static const startBombChance = 0.05;
  static const maxBombChance = 0.2;
  static const rampSeconds = 90.0;

  double spawnInterval(double elapsed) {
    final t = min(elapsed / rampSeconds, 1.0);
    return startInterval - (startInterval - minInterval) * t;
  }

  double bombChance(double elapsed) {
    final t = min(elapsed / rampSeconds, 1.0);
    return startBombChance + (maxBombChance - startBombChance) * t;
  }
}
