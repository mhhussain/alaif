import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/ink_particles.dart';

/// Renders a one-shot particle burst (ink splatter or gold dust).
///
/// Particle positions are absolute game coordinates, so this component sits
/// at the origin and simply draws every live particle each frame. It removes
/// itself once every particle is dead.
class InkBurstComponent extends Component {
  InkBurstComponent({required this.particles}) {
    priority = 60; // over letters (default 0), under the blade (100)
  }

  final List<InkParticle> particles;

  final ui.Paint _paint = ui.Paint();

  @override
  void update(double dt) {
    for (final p in particles) {
      p.update(dt);
    }
    if (particles.every((p) => p.dead)) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    for (final p in particles) {
      if (p.dead) continue;
      _paint.color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(
        ui.Offset(p.position.x, p.position.y),
        p.radius,
        _paint,
      );
    }
  }
}
