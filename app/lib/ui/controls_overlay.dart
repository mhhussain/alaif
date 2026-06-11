import 'package:flutter/material.dart';

import '../game/alaif_game.dart';
import 'design_tokens.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0, right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.pause, color: AlaifColors.inkMuted, size: 32),
            onPressed: game.pauseGame,
          ),
        ),
      ),
    );
  }
}
