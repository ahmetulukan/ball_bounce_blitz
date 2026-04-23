import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class ScorePopup extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final int score;
  double elapsed = 0;
  static const double lifetime = 0.8;

  ScorePopup({required Vector2 position, required this.score}) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    position.y -= 40 * dt;
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / lifetime;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.3;

    final text = '+$score';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.amber.withAlpha((alpha * 255).toInt()),
          shadows: const [Shadow(color: Color(0x80000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
