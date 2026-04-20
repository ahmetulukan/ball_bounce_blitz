import 'package:flutter/material.dart';

class GameOverScreen extends StatelessWidget {
  final int score;
  const GameOverScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GAME OVER', style: TextStyle(color: Color(0xFFE91E63), fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Score: $score', style: const TextStyle(color: Colors.white, fontSize: 32)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFEB3B), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              child: const Text('RESTART', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}