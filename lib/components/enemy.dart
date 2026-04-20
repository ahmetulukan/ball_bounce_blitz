import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';
import 'ball.dart';
import 'paddle.dart';

class Enemy extends PositionComponent with HasGameRef<BallBounceBlitzGame> {
  double speed;
  static const double width = 30;
  static const double height = 30;

  Enemy({required double x, required double y, required this.speed}) : super(anchor: Anchor.center) {
    position = Vector2(x, y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;

    if (position.y > gameRef.size.y + 50) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE91E63);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball || other is Paddle) {
      removeFromParent();
    }
  }
}