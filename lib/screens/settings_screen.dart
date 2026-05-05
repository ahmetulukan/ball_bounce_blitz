import 'package:flutter/material.dart';
import '../game/game.dart';

class SettingsScreen extends StatelessWidget {
  final BallBounceBlitzGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        foregroundColor: Colors.white,
        title: const Text('⚙️ Settings'),
      ),
      body: const Center(
        child: Text(
          'Settings coming soon!',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
