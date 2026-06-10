import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/trail_buffer.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Full-screen drag catcher: records the swipe, draws the brush-ink trail,
/// and reports each new segment to the game for slicing.
class BladeTrail extends PositionComponent
    with DragCallbacks, HasGameReference<AlaifGame> {
  final TrailBuffer buffer =
      TrailBuffer(maxAge: AlaifMotion.bladeRetentionMs / 1000);
  double _time = 0;

  /// Stroke width for segment [segmentIndex] (1-based) of [segmentCount]
  /// segments. Linear taper: segment 1 (tail, oldest) = bladeMinWidth,
  /// segment [segmentCount] (head, newest) = bladeWidth.
  static double strokeWidthFor(int segmentIndex, int segmentCount) {
    if (segmentCount <= 1) return AlaifMotion.bladeWidth;
    final t = (segmentIndex - 1) / (segmentCount - 1);
    return AlaifMotion.bladeMinWidth +
        (AlaifMotion.bladeWidth - AlaifMotion.bladeMinWidth) * t;
  }

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
    if (game.paused) return;
    super.onDragStart(event);
    buffer.clear();
    buffer.add(event.localPosition, _time);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.paused) return; // ignore swipes while the pause overlay is up
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
    final segmentCount = pts.length - 1;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1].position;
      final b = pts[i].position;
      canvas.drawLine(
        ui.Offset(a.x, a.y),
        ui.Offset(b.x, b.y),
        ui.Paint()
          ..color = AlaifColors.bladeInk
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = strokeWidthFor(i, segmentCount)
          ..strokeCap = ui.StrokeCap.round,
      );
    }
  }
}
