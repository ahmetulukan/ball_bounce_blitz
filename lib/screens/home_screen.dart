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
  bool _showTutorial = false;

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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _showTutorial = true),
                  child: const Text('📖 HOW TO PLAY', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 14)),
                ),
              ],
            ),
          ),
          // Tutorial overlay
          if (_showTutorial) _buildTutorialOverlay(),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black.withAlpha(230),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00BCD4).withAlpha(100)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📖 HOW TO PLAY', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _tutRow('🕹', 'Move paddle left/right'),
              _tutRow('⚡', 'Hit enemies to score points'),
              _tutRow('🔥', 'Build combos for bonus points'),
              _tutRow('🎯', 'Hit paddle edges for critical hits (25 pts)'),
              _tutRow('💥', 'Chain reactions destroy nearby enemies'),
              _tutRow('🌊', 'Waves increase difficulty over time'),
              _tutRow('👑', 'Boss appears every 5 waves'),
              const SizedBox(height: 16),
              const Text('Power-Ups:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _tutRow('⚡', 'Speed - Ball speeds up'),
              _tutRow('🛡️', 'Shield - Extra life'),
              _tutRow('✖3', 'Multi-Ball - Spawn 2 extra balls'),
              _tutRow('🔻', 'Shrink - Narrow enemies'),
              _tutRow('🧲', 'Magnet - Ball follows paddle'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _showTutorial = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('GOT IT!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tutRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
