import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class HitSpark extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<Spark> sparks = [];
  double elapsed = 0;
  final double lifetime = 0.3;
  final Color color;

  HitSpark({
    required Vector2 position,
    this.color = const Color(0xFFFFFFFF),
  }) : super(position: position, anchor: Anchor.center) {
    final rand = Random();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 3.14159 * 2 + rand.nextDouble() * 0.5;
      final speed = 120 + rand.nextDouble() * 80;
      sparks.add(Spark(
        offset: Offset.zero,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: 2 + rand.nextDouble() * 2,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    for (final s in sparks) {
      s.offset = Offset(s.offset.dx + s.velocity.x * dt, s.offset.dy + s.velocity.y * dt);
      s.velocity = s.velocity * 0.85;
    }
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - elapsed / lifetime).clamp(0.0, 1.0);
    for (final s in sparks) {
      final paint = Paint()
        ..color = color.withAlpha((alpha * 255).toInt())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.offset, s.size * (1 - elapsed / lifetime), paint);
    }
  }
}

class Spark {
  Offset offset;
  Vector2 velocity;
  double size;
  Spark({required this.offset, required this.velocity, required this.size});
}