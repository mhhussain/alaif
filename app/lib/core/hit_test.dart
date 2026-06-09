import 'package:flame/components.dart';

/// True if the segment [a]→[b] passes within [radius] of [center].
bool segmentHitsCircle(Vector2 a, Vector2 b, Vector2 center, double radius) {
  final ab = b - a;
  final len2 = ab.length2;
  final t = len2 == 0 ? 0.0 : ((center - a).dot(ab) / len2).clamp(0.0, 1.0);
  final closest = a + ab * t;
  return closest.distanceToSquared(center) <= radius * radius;
}
