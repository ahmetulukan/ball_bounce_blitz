import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/ball_bounce_game.dart';
import 'game/ui/game_over_screen.dart';
import 'game/ui/hud_widget.dart';
import 'game/ui/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BallBounceApp());
}

class BallBounceApp extends StatelessWidget {
  const BallBounceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Bounce Blitz',
      debugShowCheckedModeBanner: false,
      home: GameWidget<BallBounceGame>.controlled(
        gameFactory: () => BallBounceGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverScreen(game: game),
          'Hud': (context, game) => HudWidget(game: game),
          'MainMenu': (context, game) => MainMenuScreen(game: game),
        },
        initialActiveOverlays: const ['MainMenu'],
      ),
    );
  }
}
