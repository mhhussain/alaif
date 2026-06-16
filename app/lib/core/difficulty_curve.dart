/// Score-driven difficulty model for v2. Supersedes the v1 time-based ramp.
/// A [Stage] carries every per-stage spawning parameter; [stageFor] maps the
/// current score to its stage. Pure Dart — no Flame/Flutter dependency.
class Stage {
  const Stage({
    required this.name,
    required this.baselineInterval,
    required this.batchMin,
    required this.batchMax,
    required this.letterSpeed,
    required this.bombChance,
    required this.surgeCadence,
    required this.surgeCount,
    required this.surgeLetterWeight,
    required this.surgeBombWeight,
    required this.surgeBothWeight,
  });

  /// Display/debug name: 'Calm' | 'Brisk' | 'Frenzy'.
  final String name;

  /// Seconds between baseline spawn ticks.
  final double baselineInterval;

  /// Inclusive range of letters/bombs emitted per baseline tick.
  final int batchMin;
  final int batchMax;

  /// Multiplier on the spawn arc's vertical launch speed.
  final double letterSpeed;

  /// Chance a given baseline spawn is a bomb instead of a letter.
  final double bombChance;

  /// Seconds between surge rolls while in this stage.
  final double surgeCadence;

  /// Items emitted by one surge.
  final int surgeCount;

  /// Surge-type probability weights (sum to 1.0).
  final double surgeLetterWeight;
  final double surgeBombWeight;
  final double surgeBothWeight;
}

const kCalm = Stage(
  name: 'Calm',
  baselineInterval: 1.10,
  batchMin: 1,
  batchMax: 1,
  letterSpeed: 1.00,
  bombChance: 0.05,
  surgeCadence: 12.0,
  surgeCount: 3,
  surgeLetterWeight: 0.80,
  surgeBombWeight: 0.10,
  surgeBothWeight: 0.10,
);

const kBrisk = Stage(
  name: 'Brisk',
  baselineInterval: 0.80,
  batchMin: 1,
  batchMax: 2,
  letterSpeed: 1.15,
  bombChance: 0.12,
  surgeCadence: 10.0,
  surgeCount: 5,
  surgeLetterWeight: 0.55,
  surgeBombWeight: 0.25,
  surgeBothWeight: 0.20,
);

const kFrenzy = Stage(
  name: 'Frenzy',
  baselineInterval: 0.55,
  batchMin: 2,
  batchMax: 3,
  letterSpeed: 1.30,
  bombChance: 0.20,
  surgeCadence: 8.0,
  surgeCount: 8,
  surgeLetterWeight: 0.35,
  surgeBombWeight: 0.35,
  surgeBothWeight: 0.30,
);

/// Maps the current [score] to its difficulty [Stage].
Stage stageFor(int score) {
  if (score < 300) return kCalm;
  if (score < 900) return kBrisk;
  return kFrenzy;
}
