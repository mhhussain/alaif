import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/alaif_game.dart';
import 'ui/alaif_theme.dart';
import 'ui/controls_overlay.dart';
import 'ui/game_over_overlay.dart';
import 'ui/how_to_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/settings_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AlaifApp());
}

class AlaifApp extends StatelessWidget {
  const AlaifApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAlaifTheme(),
      home: Scaffold(
        body: SafeArea(
          child: GameWidget<AlaifGame>.controlled(
            gameFactory: AlaifGame.new,
            overlayBuilderMap: {
              'menu': (context, game) => MenuOverlay(game: game),
              'gameOver': (context, game) => GameOverOverlay(game: game),
              'paused': (context, game) => PauseOverlay(game: game),
              'controls': (context, game) => ControlsOverlay(game: game),
              'howTo': (context, game) => HowToOverlay(game: game),
              'settings': (context, game) => SettingsOverlay(game: game),
            },
          ),
        ),
      ),
    );
  }
}
