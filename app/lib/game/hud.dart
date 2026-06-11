import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../core/game_rules.dart';
import '../core/score_format.dart';
import '../ui/design_tokens.dart';
import 'alaif_game.dart';

/// In-game HUD (spec §4.3): "SCORE" label + comma-grouped score top-left,
/// lives top-right as three 14px dots (filled ink = alive, hairline ring =
/// lost). Sits under the blade (priority 90 < 100).
///
/// The game canvas now paints edge-to-edge (no `SafeArea` ancestor), so the
/// HUD offsets its top-left/top-right anchors by [AlaifGame.safePadding].
class Hud extends PositionComponent with HasGameReference<AlaifGame> {
  Hud() : super(priority: 90);

  static const dotRadius = 7.0; // 14px dots
  static const dotGap = 24.0;

  static final TextPaint _labelPaint = TextPaint(style: AlaifType.label);
  static final TextPaint _scorePaint = TextPaint(style: AlaifType.scoreHud);

  String get scoreText => formatScore(game.scoreState.score);

  /// Dot [index] (0..2, left to right) is filled while that life remains.
  bool dotFilled(int index) => index < game.rules.lives;

  /// Top-left origin of the "SCORE" label, after safe-area insets.
  Vector2 get scoreOrigin => Vector2(
        AlaifSpacing.xl + game.safePadding.left,
        AlaifSpacing.lg + game.safePadding.top,
      );

  /// X position of the rightmost lives dot, after safe-area insets.
  double get livesRowRight =>
      size.x - AlaifSpacing.xl - game.safePadding.right;

  /// Y position (vertical center) of the lives-dot row, after safe-area insets.
  double get livesRowCenterY =>
      AlaifSpacing.lg + 14 + game.safePadding.top;

  @override
  void onLoad() {
    position = Vector2.zero();
    size = game.size.clone();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void render(ui.Canvas canvas) {
    // Score block, top-left.
    final origin = scoreOrigin;
    _labelPaint.render(canvas, 'SCORE', origin);
    _scorePaint.render(canvas, scoreText, Vector2(origin.x, origin.y + 18));

    // Lives dots, top-right.
    final cy = livesRowCenterY;
    final right = livesRowRight;
    for (var i = 0; i < GameRules.startingLives; i++) {
      final cx = right - (GameRules.startingLives - 1 - i) * dotGap;
      if (dotFilled(i)) {
        canvas.drawCircle(
          ui.Offset(cx, cy),
          dotRadius,
          ui.Paint()..color = AlaifColors.ink,
        );
      } else {
        canvas.drawCircle(
          ui.Offset(cx, cy),
          dotRadius,
          ui.Paint()
            ..color = AlaifColors.hairline
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }
}
