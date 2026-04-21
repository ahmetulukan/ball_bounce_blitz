import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/game.dart';
import 'home_screen.dart';
import 'game_over_screen.dart';

class GameScreen extends StatelessWidget {
  GameScreen({super.key});

  final BallBounceBlitzGame game = BallBounceBlitzGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (ctx) => HomeScreen(),
        '/game': (ctx) => Scaffold(
          body: GameWidget(
            game: game,
            overlayBuilderMap: {
              'GameOver': (_, game) => GameOverScreen(
                score: (game as BallBounceBlitzGame).lastScore,
                highScore: game.highScore,
                onRestart: () => game.restart(),
              ),
            },
            backgroundBuilder: (_) => Container(color: Color(0xFF0D0D1A)),
          ),
        ),
      },
    );
  }
}
