import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/ball_bounce_game.dart';
import 'game/ui/game_over_screen.dart';
import 'game/ui/hud_widget.dart';
import 'game/ui/main_menu_screen.dart';
import 'game/ui/pause_screen.dart';
import 'game/ui/wave_announcement.dart';
import 'game/ui/achievements_overlay.dart';
import '../screens/tournament_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../../services/leaderboard_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize leaderboard service
  final leaderboard = LeaderboardService();
  await leaderboard.init();

  runApp(BallBounceApp(leaderboard: leaderboard));
}

class BallBounceApp extends StatelessWidget {
  final LeaderboardService leaderboard;

  const BallBounceApp({super.key, required this.leaderboard});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Bounce Blitz',
      debugShowCheckedModeBanner: false,
      home: GameWidget<BallBounceGame>.controlled(
        gameFactory: () => BallBounceGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) => GameOverScreen(
            score: game.score,
            highScore: game.highScore,
            wave: game.wave,
            enemiesDestroyed: game.totalEnemiesDestroyed,
            onRestart: () => game.restart(),
          ),
          'Hud': (context, game) => HudWidget(game: game),
          'MainMenu': (context, game) => MainMenuScreen(game: game),
          'Pause': (context, game) => PauseScreen(game: game),
          'WaveAnnouncement': (context, game) => WaveAnnouncement(
            wave: game.wave,
            onComplete: () => game.overlays.remove('WaveAnnouncement'),
          ),
          'Achievements': (context, game) => Material(
            color: Colors.black.withValues(alpha: 0.7),
            child: AchievementsListWidget(
              onClose: () => game.overlays.remove('Achievements'),
            ),
          ),
          'Tournament': (context, game) => TournamentScreen(game: game),
          'Leaderboard': (context, game) => LeaderboardScreen(
            game: game,
            leaderboard: leaderboard,
          ),
        },
        initialActiveOverlays: const ['MainMenu'],
      ),
    );
  }
}