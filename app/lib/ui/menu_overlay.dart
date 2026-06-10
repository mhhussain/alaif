import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Main menu (spec §4.1): seal stamp + label + Arabic accent, italic
/// wordmark over a seal rule, BEST score, ink Play button, and two text
/// links. A faint giant lam watermarks the bottom-right of the paper.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          right: -30,
          bottom: -60,
          child: IgnorePointer(
            child: Text(
              'ل',
              style: TextStyle(
                fontFamily: AlaifFonts.arabic,
                fontSize: 320,
                color: Color(0x0D1B1712), // 5% ink watermark
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AlaifSpacing.screenPad,
            vertical: AlaifSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 14, height: 14, color: AlaifColors.seal),
                  const SizedBox(width: AlaifSpacing.sm),
                  const Text('A SLICING GAME', style: AlaifType.label),
                  const Spacer(),
                  const Text('الألِف', style: AlaifType.titleArabic),
                ],
              ),
              const Spacer(),
              const Text('Alaif', style: AlaifType.titleDisplay),
              const SizedBox(height: AlaifSpacing.md),
              Container(width: 64, height: 2, color: AlaifColors.seal),
              const SizedBox(height: AlaifSpacing.lg),
              const SizedBox(
                width: 230,
                child: Text(
                  'Swipe to slice the falling letters.',
                  style: AlaifType.bodyMuted,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('BEST', style: AlaifType.label),
                  const Spacer(),
                  FutureBuilder<int>(
                    future: game.highScores.read(),
                    builder: (context, snapshot) => Text(
                      formatScore(snapshot.data ?? 0),
                      style: AlaifType.scoreHud.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AlaifSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: game.startGame,
                  child: const Text('Play'),
                ),
              ),
              const SizedBox(height: AlaifSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: game.openHowTo,
                    child: const Text('How to play'),
                  ),
                  const SizedBox(width: AlaifSpacing.lg),
                  TextButton(
                    onPressed: () => game.openSettings(from: 'menu'),
                    child: const Text('Sound'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
