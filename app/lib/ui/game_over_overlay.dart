import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Game Over',
              style: TextStyle(fontSize: 48, color: Colors.white)),
          const SizedBox(height: 16),
          Text('Score: ${game.scoreState.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white)),
          FutureBuilder<int>(
            future: game.highScores.read(),
            builder: (context, snapshot) => Text(
              'Best: ${snapshot.data ?? 0}',
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: game.startGame,
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}
