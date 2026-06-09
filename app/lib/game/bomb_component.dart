import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/arc_motion.dart';

class BombComponent extends PositionComponent {
  BombComponent({required this.motion}) {
    size = Vector2.all(80);
    anchor = Anchor.center;
    position = motion.positionAt(0);
  }

  final ArcMotion motion;
  double _age = 0;
  bool entered = false;

  double get hitRadius => size.x / 2;

  @override
  void update(double dt) {
    _age += dt;
    position = motion.positionAt(_age);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, ui.Paint()..color = const ui.Color(0xFF1B1B1B));
    canvas.drawCircle(
      center,
      size.x / 2,
      ui.Paint()
        ..color = const ui.Color(0xFFFF4444)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}
