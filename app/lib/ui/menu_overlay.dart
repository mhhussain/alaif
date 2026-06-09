import 'package:flutter/material.dart';

import '../game/alaif_game.dart';

class MenuOverlay extends StatelessWidget {
  const MenuOverlay({super.key, required this.game});

  final AlaifGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Alaif',
              style: TextStyle(fontSize: 64, color: Colors.white)),
          const SizedBox(height: 16),
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
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }
}
