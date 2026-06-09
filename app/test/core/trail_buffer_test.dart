import 'package:alaif/core/trail_buffer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps recent points', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.00);
    buffer.add(Vector2(1, 1), 1.05);
    expect(buffer.points.length, 2);
  });

  test('prunes points older than maxAge', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.00);
    buffer.add(Vector2(1, 1), 1.05);
    buffer.prune(1.20);
    expect(buffer.points, isEmpty);
  });

  test('clear empties the buffer', () {
    final buffer = TrailBuffer(maxAge: 0.1);
    buffer.add(Vector2(0, 0), 1.0);
    buffer.clear();
    expect(buffer.points, isEmpty);
  });
}
