import 'package:alaif/core/hit_test.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('segment crossing the circle hits', () {
    expect(
      segmentHitsCircle(Vector2(0, 50), Vector2(100, 50), Vector2(50, 50), 10),
      isTrue,
    );
  });

  test('segment far from the circle misses', () {
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(100, 0), Vector2(50, 50), 10),
      isFalse,
    );
  });

  test('closest point clamps to segment endpoints', () {
    // Circle sits beyond the end of the segment, just out of reach.
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(25, 0), 10),
      isFalse,
    );
    // ...and just within reach of the endpoint.
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(19, 0), 10),
      isTrue,
    );
  });

  test('zero-length segment acts as a point', () {
    expect(
      segmentHitsCircle(Vector2(5, 5), Vector2(5, 5), Vector2(5, 8), 10),
      isTrue,
    );
  });

  test('boundary distance counts as a hit', () {
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(20, 0), 10),
      isTrue,
    );
    expect(
      segmentHitsCircle(Vector2(0, 0), Vector2(10, 0), Vector2(20.01, 0), 10),
      isFalse,
    );
  });
}
