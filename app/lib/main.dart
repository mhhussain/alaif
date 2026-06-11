import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/alaif_game.dart';
import 'ui/alaif_theme.dart';
import 'ui/controls_overlay.dart';
import 'ui/design_tokens.dart';
import 'ui/game_over_overlay.dart';
import 'ui/how_to_overlay.dart';
import 'ui/menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/settings_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
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
        backgroundColor: AlaifColors.paper,
        body: const _GameHost(),
      ),
    );
  }
}

/// Hosts the [AlaifGame] instance and keeps its [AlaifGame.safePadding]
/// in sync with the current [MediaQuery] insets on every rebuild (e.g.
/// when the device rotates or system insets otherwise change).
class _GameHost extends StatefulWidget {
  const _GameHost();

  @override
  State<_GameHost> createState() => _GameHostState();
}

class _GameHostState extends State<_GameHost> {
  late final AlaifGame _game = AlaifGame();

  @override
  Widget build(BuildContext context) {
    _game.safePadding = MediaQuery.paddingOf(context);
    return GameWidget<AlaifGame>(
      game: _game,
      overlayBuilderMap: {
        'menu': (context, game) => MenuOverlay(game: game),
        'gameOver': (context, game) => GameOverOverlay(game: game),
        'paused': (context, game) => PauseOverlay(game: game),
        'controls': (context, game) => ControlsOverlay(game: game),
        'howTo': (context, game) => HowToOverlay(game: game),
        'settings': (context, game) => SettingsOverlay(game: game),
      },
    );
  }
}
