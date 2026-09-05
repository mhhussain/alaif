import 'dart:math';

import 'package:flame/components.dart';

import '../core/arc_motion.dart';
import '../ui/design_tokens.dart';

/// Max radians a single launch is rotated off its base arc (~7°), so a
/// cluster spawned in one tick spreads out instead of stacking.
const launchJitter = 0.12;

/// Random launch arc from just below the bottom edge: horizontal position in
/// the middle 70% of the screen, drift toward screen center, apex at 70–95%
/// of screen height. [speedMultiplier] scales the vertical launch speed
/// (stage letter-speed for baseline; boosted for surges).
ArcMotion randomLaunchArc(Vector2 screen, Random random,
    {double speedMultiplier = 1}) {
  final x = screen.x * (0.15 + 0.7 * random.nextDouble());
  final start = Vector2(x, screen.y + 60);
  final vx = (screen.x / 2 - x) * (0.3 + 0.4 * random.nextDouble());
  final vy =
      -screen.y * (0.877 + 0.145 * random.nextDouble()) * speedMultiplier;
  final velocity = Vector2(vx, vy)
    ..rotate((random.nextDouble() * 2 - 1) * launchJitter);
  return ArcMotion(
    start: start,
    velocity: velocity,
    gravity: screen.y * 0.55,
  );
}

/// Random glyph card size within the spawn range.
double randomGlyphTargetSize(Random random) =>
    AlaifGlyph.spawnSizeMin +
    (AlaifGlyph.spawnSizeMax - AlaifGlyph.spawnSizeMin) * random.nextDouble();
