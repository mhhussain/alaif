import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/trail_buffer.dart';
import 'alaif_game.dart';

/// Full-screen drag catcher: records the swipe, draws the trail,
/// and reports each new segment to the game for slicing.
class BladeTrail extends PositionComponent
    with DragCallbacks, HasGameReference<AlaifGame> {
  final TrailBuffer buffer = TrailBuffer();
  double _time = 0;

  @override
  void onLoad() {
    position = Vector2.zero();
    size = game.size.clone();
    priority = 100;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    _time += dt;
    buffer.prune(_time);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    buffer.clear();
    buffer.add(event.localPosition, _time);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final previous =
        buffer.points.isEmpty ? null : buffer.points.last.position;
    buffer.add(event.localEndPosition, _time);
    if (previous != null) {
      game.trySlice(previous, event.localEndPosition);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    game.endSwipe();
    buffer.clear();
  }

  @override
  void render(ui.Canvas canvas) {
    final pts = buffer.points;
    if (pts.length < 2) return;
    final path = ui.Path()
      ..moveTo(pts.first.position.x, pts.first.position.y);
    for (final p in pts.skip(1)) {
      path.lineTo(p.position.x, p.position.y);
    }
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round,
    );
  }
}
