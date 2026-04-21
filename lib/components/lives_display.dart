import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class LivesDisplay extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  int lives;
  static const double heartSize = 24;
  static const double spacing = 30;

  LivesDisplay({this.lives = 3}) : super(anchor: Anchor.topLeft, position: Vector2(16, 16));

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < lives; i++) {
      final paint = Paint()..color = const Color(0xFFE91E63);
      final cx = i * spacing + heartSize / 2;
      final cy = heartSize / 2;
      canvas.drawCircle(Offset(cx, cy - 2), heartSize / 3, paint);
      canvas.drawCircle(Offset(cx + heartSize / 3.5, cy - 2), heartSize / 3, paint);
      final path = Path()
        ..moveTo(cx - heartSize / 3, cy)
        ..lineTo(cx + heartSize / 3, cy)
        ..lineTo(cx, cy + heartSize / 2.5)
        ..close();
      canvas.drawPath(path, paint);
    }
  }
}