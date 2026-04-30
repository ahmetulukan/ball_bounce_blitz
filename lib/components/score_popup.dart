import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

/// Floating score popup that drifts upward and fades out
class ScorePopup extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final String text;
  final Color color;
  double elapsed = 0;
  static const double lifetime = 0.8;
  static const double speed = 60;

  ScorePopup({
    required Vector2 position,
    required this.text,
    this.color = const Color(0xFFFFEB3B),
  }) : super(position: position.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    position.y -= speed * dt;
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / lifetime;
    final alpha = (1 - progress * progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.3;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha((alpha * 255).toInt()),
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
  }
}
