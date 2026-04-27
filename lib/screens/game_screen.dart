import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/game.dart';
import 'home_screen.dart';
import 'pause_screen.dart';
import 'game_over_screen.dart';

class GameScreen extends StatelessWidget {
  GameScreen({super.key});

  final BallBounceBlitzGame game = BallBounceBlitzGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (ctx) => HomeScreen(game: game),
        '/game': (ctx) {
          final g = game;
          return Scaffold(
            body: GameWidget(
              game: g,
              overlayBuilderMap: {
                'Pause': (ctx, game) => PauseScreen(game: game as BallBounceBlitzGame),
                'GameOver': (ctx, game) {
                  final g = game as BallBounceBlitzGame;
                  return GameOverScreen(
                    score: g.lastScore,
                    highScore: g.highScore,
                    wave: g.lastWave,
                    enemiesDestroyed: g.lastEnemiesDestroyed,
                    onRestart: () => g.restart(),
                  );
                },
              },
              backgroundBuilder: (_) => Container(color: const Color(0xFF0D0D1A)),
            ),
          );
        },
      },
    );
  }
}
