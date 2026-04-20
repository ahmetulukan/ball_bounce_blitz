import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class HudOverlay extends StatelessWidget {
  final BallBounceGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SCORE: ${game.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Wave
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(180),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'WAVE ${game.wave}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Lives
              Row(
                children: List.generate(3, (index) {
                  final isActive = index < game.lives;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.favorite,
                      color: isActive ? Colors.red : Colors.grey,
                      size: 24,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
