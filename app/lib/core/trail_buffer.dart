import 'package:flame/components.dart';

/// An immutable snapshot of a swipe position and the game-time it was recorded.
class TrailPoint {
  TrailPoint(this.position, this.time);
  final Vector2 position;
  final double time;
}

/// Holds the last [maxAge] seconds of swipe points.
class TrailBuffer {
  TrailBuffer({this.maxAge = 0.1});

  final double maxAge;
  final List<TrailPoint> _points = [];

  List<TrailPoint> get points => List.unmodifiable(_points);

  void add(Vector2 position, double time) {
    _points.add(TrailPoint(position.clone(), time));
    prune(time);
  }

  /// Removes points strictly older than [maxAge]; a point exactly [maxAge] old is retained.
  void prune(double now) {
    _points.removeWhere((p) => now - p.time > maxAge);
  }

  void clear() => _points.clear();
}
