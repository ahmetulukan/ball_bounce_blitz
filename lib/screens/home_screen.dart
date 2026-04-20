import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('BALL BOUNCE BLITZ', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            const Text('Tap to Start', style: TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              child: const Text('PLAY', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}