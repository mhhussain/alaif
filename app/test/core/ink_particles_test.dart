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
