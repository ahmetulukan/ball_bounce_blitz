import 'package:flutter/material.dart';
import '../game/game.dart';

class HomeScreen extends StatefulWidget {
  final BallBounceBlitzGame game;
  const HomeScreen({super.key, required this.game});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final hs = await widget.game.loadHighScore();
    if (mounted) setState(() => _highScore = hs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E)],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '⚡ BALL BOUNCE\n     BLITZ',
                  style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bounce • Survive • Dominate',
                  style: TextStyle(color: Colors.white38, fontSize: 14, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                if (_highScore > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEB3B).withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFEB3B).withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('Best: $_highScore', style: const TextStyle(color: Color(0xFFFFEB3B), fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const SizedBox(height: 32),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('PLAY', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 3)),
                ),
                const SizedBox(height: 32),
                const Text(
                  '🕹 Drag paddle to move\n⚡ Hit enemies to score\n🌊 Survive waves to win',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
