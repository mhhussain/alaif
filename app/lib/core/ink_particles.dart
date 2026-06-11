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
