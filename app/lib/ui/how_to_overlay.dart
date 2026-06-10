import 'package:flutter/material.dart';

import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// How to play (spec §4.2): three icon-tile rows + a bottom-pinned primary.
class HowToOverlay extends StatelessWidget {
  const HowToOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AlaifColors.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlaifSpacing.screenPad,
            vertical: AlaifSpacing.xl,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 14, height: 14, color: AlaifColors.seal),
                        const SizedBox(height: AlaifSpacing.lg),
                        const Text('How to play', style: AlaifType.heading),
                        const SizedBox(height: AlaifSpacing.xxl),
                        const _HowToRow(
                          painter: _SwipeStrokePainter(),
                          title: 'Swipe to slice',
                          body:
                              'Drag a quick stroke through a letter to cut it in two.',
                        ),
                        const SizedBox(height: AlaifSpacing.xl),
                        const _HowToRow(
                          painter: _ComboDotsPainter(),
                          title: 'Chain combos',
                          body:
                              'Cut three or more in one swipe for bonus gold dust.',
                        ),
                        const SizedBox(height: AlaifSpacing.xl),
                        const _HowToRow(
                          painter: _BombIconPainter(),
                          title: 'Avoid the bombs',
                          body: 'Slicing a seal-ringed bomb costs you a life.',
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: game.closeHowTo,
                            child: const Text('Got it'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HowToRow extends StatelessWidget {
  const _HowToRow({
    required this.painter,
    required this.title,
    required this.body,
  });

  final CustomPainter painter;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: AlaifColors.hairline),
            borderRadius: BorderRadius.circular(AlaifRadii.sm),
          ),
          child: CustomPaint(painter: painter),
        ),
        const SizedBox(width: AlaifSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AlaifType.subheading),
              const SizedBox(height: AlaifSpacing.xs),
              Text(body, style: AlaifType.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}

/// Curved ink stroke with an arrowhead.
class _SwipeStrokePainter extends CustomPainter {
  const _SwipeStrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlaifColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.15,
        size.width * 0.8,
        size.height * 0.3,
      );
    canvas.drawPath(path, paint);
    // Arrowhead at the stroke's end.
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.66, size.height * 0.24),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.72, size.height * 0.44),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Three ink dots with gold-dust specks.
class _ComboDotsPainter extends CustomPainter {
  const _ComboDotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = AlaifColors.ink;
    final dust = Paint()..color = AlaifColors.goldDust;
    final cy = size.height * 0.55;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.25 + 0.25 * i), cy),
        4,
        ink,
      );
    }
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.28), 1.5, dust);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.22), 2, dust);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.34), 1.5, dust);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini ink bomb with the seal ring and a gold spark.
class _BombIconPainter extends CustomPainter {
  const _BombIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    const radius = 13.0;
    canvas.drawCircle(center, radius, Paint()..color = AlaifColors.ink);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AlaifColors.seal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      center.translate(radius * 0.8, -radius * 1.15),
      2,
      Paint()..color = AlaifColors.goldDust,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
