import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Game over (spec §4.5): bottom-anchored "The blade rests", final score,
/// BEST / BEST COMBO stat columns split by a hairline, Play again + Main menu.
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
        vertical: AlaifSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Text(
            'The blade rests',
            style: AlaifType.combo,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.lg),
          const Text(
            'FINAL SCORE',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xs),
          Text(
            formatScore(game.scoreState.score),
            style: AlaifType.scoreLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xl),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('BEST', style: AlaifType.label),
                      const SizedBox(height: AlaifSpacing.xs),
                      FutureBuilder<int>(
                        future: game.highScores.read(),
                        builder: (context, snapshot) => Text(
                          formatScore(snapshot.data ?? 0),
                          style: AlaifType.scoreHud.copyWith(fontSize: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(color: AlaifColors.hairline),
                Expanded(
                  child: Column(
                    children: [
                      const Text('BEST COMBO', style: AlaifType.label),
                      const SizedBox(height: AlaifSpacing.xs),
                      Text(
                        formatScore(game.scoreState.bestCombo),
                        style: AlaifType.scoreHud.copyWith(fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AlaifSpacing.xxl),
          ElevatedButton(
            onPressed: game.startGame,
            child: const Text('Play again'),
          ),
          const SizedBox(height: AlaifSpacing.md),
          OutlinedButton(
            onPressed: game.quitToMenu,
            child: const Text('Main menu'),
          ),
        ],
      ),
    );
  }
}
