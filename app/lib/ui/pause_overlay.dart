import 'package:flutter/material.dart';

import '../core/score_format.dart';
import '../game/alaif_game.dart';
import 'design_tokens.dart';

/// Pause (spec §4.4): paper scrim over the frozen game, current score,
/// Resume primary, Restart/Settings ghosts, Quit-to-menu link.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AlaifColors.scrim,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AlaifSpacing.screenPad,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PAUSED',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.lg),
          Text(
            formatScore(game.scoreState.score),
            style: AlaifType.scoreLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.sm),
          const Text(
            'CURRENT SCORE',
            style: AlaifType.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AlaifSpacing.xxl),
          ElevatedButton(
            onPressed: game.resumeFromPause,
            child: const Text('Resume'),
          ),
          const SizedBox(height: AlaifSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: game.startGame,
                  child: const Text('Restart'),
                ),
              ),
              const SizedBox(width: AlaifSpacing.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => game.openSettings(from: 'paused'),
                  child: const Text('Settings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AlaifSpacing.md),
          TextButton(
            onPressed: game.quitToMenu,
            child: const Text('Quit to menu'),
          ),
        ],
      ),
    );
  }
}
