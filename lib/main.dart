import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/ball_bounce_game.dart';
import 'game/ui/game_over_screen.dart';
import 'game/ui/hud_widget.dart';
import 'game/ui/main_menu_screen.dart';
import 'game/ui/pause_screen.dart';
import 'game/ui/wave_announcement.dart';
import 'game/ui/achievements_overlay.dart';

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
        },
        initialActiveOverlays: const ['MainMenu'],
      ),
    );
  }
}
