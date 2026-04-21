import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class PauseScreen extends StatelessWidget {
  final BallBounceGame game;

  const PauseScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87.withOpacity(0.9),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏸️ PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              _menuButton('▶ Resume', () {
                game.overlays.remove('Pause');
              }),
              const SizedBox(height: 16),
              _menuButton('🔄 Restart', () {
                game.overlays.remove('Pause');
                game.resetGame();
              }),
              const SizedBox(height: 16),
              _menuButton('🏠 Main Menu', () {
                game.overlays.remove('Pause');
                game.overlays.add('MainMenu');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16213e),
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: Colors.blue, width: 1),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}