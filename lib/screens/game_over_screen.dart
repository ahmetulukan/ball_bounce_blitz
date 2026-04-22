import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  final int highScore;
  final int wave;
  final int enemiesDestroyed;
  final VoidCallback? onRestart;
  const GameOverScreen({
    super.key,
    required this.score,
    this.highScore = 0,
    this.wave = 1,
    this.enemiesDestroyed = 0,
    this.onRestart,
  });

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
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(label: 'WAVE', value: '$wave', icon: '🌊', color: const Color(0xFF00BCD4)),
                const SizedBox(width: 16),
                _StatChip(label: 'ENEMIES', value: '$enemiesDestroyed', icon: '💥', color: const Color(0xFFE91E63)),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onRestart ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEB3B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('RESTART', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color.withAlpha(180), fontSize: 10)),
        ],
      ),
    );
  }
}
