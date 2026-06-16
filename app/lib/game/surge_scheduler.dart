import 'dart:math';

import 'package:flame/components.dart';

import '../core/difficulty_curve.dart';
import 'alaif_game.dart';
import 'spawner.dart';

enum SurgeType { letter, bomb, both }

/// Layers timed surge bursts on top of baseline spawning. On each stage's
/// cadence it rolls a [SurgeType] by the stage weights, then emits
/// [Stage.surgeCount] sub-spawns [subSpawnInterval] apart at a boosted arc
/// speed, delegating actual spawning to the [Spawner].
class SurgeScheduler extends Component with HasGameReference<AlaifGame> {
  SurgeScheduler({Random? random}) : _random = random ?? Random();

  /// Seconds between sub-spawns within a single surge.
  static const subSpawnInterval = 0.15;

  /// Extra arc-speed multiplier on top of the stage letter-speed, so a surge
  /// reads as a distinct rush rather than a faster trickle.
  static const arcSpeedBoost = 1.25;

  final Random _random;

  double _untilNext = 0; // set on mount to the current stage cadence
  int _remaining = 0; // sub-spawns left in the active surge
  double _subTimer = 0;
  SurgeType _type = SurgeType.letter;

  @override
  void onMount() {
    super.onMount();
    _untilNext = stageFor(game.scoreState.score).surgeCadence;
  }

  @override
  void update(double dt) {
    if (!game.isPlaying) return;
    final stage = stageFor(game.scoreState.score);

    if (_remaining > 0) {
      _subTimer -= dt;
      while (_remaining > 0 && _subTimer <= 0) {
        _emitOne(stage);
        _remaining -= 1;
        _subTimer += subSpawnInterval;
      }
      return;
    }

    _untilNext -= dt;
    if (_untilNext <= 0) {
      _startSurge(stage);
    }
  }

  void _startSurge(Stage stage) {
    _remaining = stage.surgeCount;
    _subTimer = 0;
    _type = _rollType(stage);
    _untilNext = stage.surgeCadence;
  }

  SurgeType _rollType(Stage stage) {
    final roll = _random.nextDouble();
    if (roll < stage.surgeLetterWeight) return SurgeType.letter;
    if (roll < stage.surgeLetterWeight + stage.surgeBombWeight) {
      return SurgeType.bomb;
    }
    return SurgeType.both;
  }

  void _emitOne(Stage stage) {
    final spawners = game.children.whereType<Spawner>();
    if (spawners.isEmpty) return;
    final spawner = spawners.first;
    if (spawner.atCapacity) return; // gated; drop this item
    final bomb = switch (_type) {
      SurgeType.letter => false,
      SurgeType.bomb => true,
      SurgeType.both => _random.nextDouble() < 0.5,
    };
    spawner.spawnItem(
      bomb: bomb,
      speedMultiplier: stage.letterSpeed * arcSpeedBoost,
    );
  }
}
