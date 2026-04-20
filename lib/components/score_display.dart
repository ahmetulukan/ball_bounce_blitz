import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class ScoreDisplay extends TextComponent with HasGameRef<BallBounceBlitzGame> {
  ScoreDisplay() : super(anchor: Anchor.topCenter, text: 'Score: 0') {
    position = Vector2(gameRef.size.x / 2, 20);
  }

  @override
  void updatePosition() {
    position = Vector2(gameRef.size.x / 2, 20);
  }

  void updateScore(int score) {
    text = 'Score: $score';
  }

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
  }
}