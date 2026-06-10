import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// Full-screen paper background: vertical paper gradient + a faint girih
/// lattice (two overlapped squares = 8-point star) tiled via an ImageShader.
///
/// The lattice tile is pre-rendered ONCE to a [ui.Image] in [onLoad]; if that
/// fails for any reason the component silently falls back to gradient-only
/// paper (spec §6 fallback).
class PaperBackground extends PositionComponent with HasGameReference<AlaifGame> {
  PaperBackground() : super(priority: -100);

  /// Side length in px of the square lattice tile.
  static const tileSize = 96;

  /// ~5% ink — the lattice must stay a whisper under the gameplay.
  static const _latticeInk = ui.Color(0x0D1B1712);

  static final Float64List _identityMatrix4 = Float64List.fromList(const [
    1, 0, 0, 0, //
    0, 1, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);

  ui.Image? _tile;
  ui.Paint? _latticePaint;
  ui.Paint? _gradientPaint;
  ui.Rect? _gradientRect;

  /// True when the lattice tile rendered successfully (false = solid fallback).
  bool get hasLattice => _tile != null;

  /// Renders one girih tile: an axis-aligned square overlapped by a 45-degree
  /// rotated square, hairline-stroked — tiled, this reads as 8-point stars.
  static Future<ui.Image> buildLatticeTile({int size = tileSize}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()
      ..color = _latticeInk
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    final s = size.toDouble();
    final center = ui.Offset(s / 2, s / 2);
    final half = s * 0.38;
    canvas.drawRect(ui.Rect.fromCircle(center: center, radius: half), paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      ui.Rect.fromCircle(center: ui.Offset.zero, radius: half),
      paint,
    );
    canvas.restore();
    return recorder.endRecording().toImage(size, size);
  }

  @override
  Future<void> onLoad() async {
    position = Vector2.zero();
    size = game.size.clone();
    try {
      _tile = await buildLatticeTile();
      _latticePaint = ui.Paint()
        ..shader = ui.ImageShader(
          _tile!,
          ui.TileMode.repeated,
          ui.TileMode.repeated,
          _identityMatrix4,
        );
    } catch (_) {
      _tile = null; // solid-paper fallback; never fatal
      _latticePaint = null;
    }
    _rebuildGradientPaint();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
    _rebuildGradientPaint();
  }

  @override
  void onRemove() {
    _tile?.dispose();
    _tile = null;
    super.onRemove();
  }

  void _rebuildGradientPaint() {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    if (rect == _gradientRect && _gradientPaint != null) return;
    _gradientRect = rect;
    _gradientPaint = ui.Paint()..shader = AlaifGradients.paper.createShader(rect);
  }

  @override
  void render(ui.Canvas canvas) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    if (rect != _gradientRect || _gradientPaint == null) {
      _rebuildGradientPaint();
    }
    canvas.drawRect(rect, _gradientPaint!);
    final latticePaint = _latticePaint;
    if (latticePaint != null) {
      canvas.drawRect(rect, latticePaint);
    }
  }
}
