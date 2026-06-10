import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.pause, color: Colors.white70, size: 32),
            onPressed: game.pauseGame,
          ),
        ),
      ),
    );
  }
}
