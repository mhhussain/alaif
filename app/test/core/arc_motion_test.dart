import 'package:alaif/core/arc_motion.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at start position', () {
    final motion = ArcMotion(start: Vector2(10, 20), velocity: Vector2(0, -100));
    expect(motion.positionAt(0), Vector2(10, 20));
  });

  test('rises then falls under gravity', () {
    final motion =
        ArcMotion(start: Vector2(0, 0), velocity: Vector2(0, -100), gravity: 100);
    expect(motion.positionAt(1).y, lessThan(0)); // above start (y is down)
    expect(motion.positionAt(3).y, greaterThan(motion.positionAt(1).y)); // falling
  });

  test('moves horizontally at constant speed', () {
    final motion =
        ArcMotion(start: Vector2(0, 0), velocity: Vector2(50, 0), gravity: 0);
    expect(motion.positionAt(2).x, 100);
  });

  test('default gravity produces a parabolic arc', () {
    final motion = ArcMotion(start: Vector2.zero(), velocity: Vector2(0, -300));
    expect(motion.positionAt(0.1).y, lessThan(0)); // rising
    expect(motion.positionAt(2).y, greaterThan(motion.positionAt(0.1).y)); // falling back down
  });
}
