import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Paused',
              style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: game.resumeFromPause,
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}
