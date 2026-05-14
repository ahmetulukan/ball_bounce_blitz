import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/ball_bounce_game.dart';
import 'home_screen.dart';
import 'pause_screen.dart';
import 'game_over_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import '../game/ui/hud_overlay.dart';
import '../game/ui/wave_announcement.dart';
import '../game/ui/main_menu_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  static BallBounceGame? _sharedGame;

  static BallBounceGame get game {
    _sharedGame ??= BallBounceGame();
    return _sharedGame!;
  }

  @override
  Widget build(BuildContext context) {
    final g = game;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (ctx) => HomeScreen(game: g),
        '/game': (ctx) => Scaffold(
          body: GameWidget(
            game: g,
            overlayBuilderMap: {
              'Pause': (ctx, game) => PauseScreen(game: game as BallBounceGame),
              'GameOver': (ctx, game) {
                final gg = game as BallBounceGame;
                return GameOverScreen(
                  score: gg.score,
                  highScore: gg.highScore,
                  wave: gg.wave,
                  enemiesDestroyed: gg.totalEnemiesDestroyed,
                  maxCombo: gg.comboSystem.maxCombo,
                  onRestart: () {
                    gg.overlays.remove('GameOver');
                    gg.startGame();
                  },
                );
              },
              'WaveAnnouncement': (ctx, game) {
                final gg = game as BallBounceGame;
                return WaveAnnouncement(
                  wave: gg.wave,
                  isBoss: gg.isBossWave,
                  onComplete: () => gg.overlays.remove('WaveAnnouncement'),
                );
              },
              'Achievements': (ctx, game) => AchievementsScreen(game: game as BallBounceGame),
              'Settings': (ctx, game) => SettingsScreen(game: game as BallBounceGame),
              'MainMenu': (ctx, game) => MainMenuScreen(game: game as BallBounceGame),
              'HUD': (ctx, game) => HudOverlay(game: game as BallBounceGame),
            },
            backgroundBuilder: (_) => Container(color: const Color(0xFF0D0D1A)),
          ),
        ),
      },
    );
  }
}
