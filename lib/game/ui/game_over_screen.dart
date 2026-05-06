import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class GameOverScreen extends StatelessWidget {
  final BallBounceGame game;

  const GameOverScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = game.score >= game.highScore && game.score > 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isNewHighScore ? const Color(0xFFFFD700) : Colors.red,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isNewHighScore ? const Color(0xFFFFD700) : Colors.red)
                    .withAlpha(80),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💀 GAME OVER',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (isNewHighScore) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        'NEW HIGH SCORE!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  '${game.highScore - game.score} points away',
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Stats grid
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(15),
                      Colors.white.withAlpha(5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _statRow('🏆 Score', '${game.score}', Colors.amber),
                    const Divider(color: Colors.white12, height: 16),
                    _statRow('👑 Best', '${game.highScore}', Colors.grey),
                    const Divider(color: Colors.white12, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statItem('🌊 Wave', '${game.wave}'),
                        _statItem('💀 Enemies', '${game.totalEnemiesDestroyed}'),
                        _statItem('🔥 Max Combo', 'x${game.comboSystem.maxCombo}'),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    _statRow(
                      '⚡ Combo Bonus',
                      'x${game.comboSystem.multiplier.toStringAsFixed(1)}',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              
              // Difficulty indicator
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mode: ${game.gameState.settings.difficultyName}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      game.overlays.remove('GameOver');
                      game.resetGame();
                      game.startGame();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔄', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      game.overlays.remove('GameOver');
                      game.overlays.add('MainMenu');
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🏠', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(120),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
