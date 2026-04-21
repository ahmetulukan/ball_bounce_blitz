import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback? onRestart;
  const GameOverScreen({super.key, required this.score, this.highScore = 0, this.onRestart});

  bool get isNewHighScore => score >= highScore && score > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GAME OVER', style: TextStyle(color: Color(0xFFE91E63), fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 32)),
            const SizedBox(height: 8),
            if (isNewHighScore)
              const Text('🏆 NEW HIGH SCORE!', style: TextStyle(color: Color(0xFFFFEB3B), fontSize: 22, fontWeight: FontWeight.bold))
            else
              Text('Best: $highScore', style: const TextStyle(color: Colors.white54, fontSize: 20)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart ?? () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFEB3B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              child: const Text('RESTART', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
