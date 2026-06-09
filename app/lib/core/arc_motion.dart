import 'package:flame/components.dart';

/// Projectile motion: constant horizontal velocity, gravity pulls +y (down).
class ArcMotion {
  ArcMotion({required Vector2 start, required Vector2 velocity, this.gravity = 900})
      : _start = start.clone(),
        _velocity = velocity.clone();

  final Vector2 _start;
  final Vector2 _velocity;
  final double gravity;

  Vector2 positionAt(double t) => Vector2(
        _start.x + _velocity.x * t,
        _start.y + _velocity.y * t + 0.5 * gravity * t * t,
      );
}
