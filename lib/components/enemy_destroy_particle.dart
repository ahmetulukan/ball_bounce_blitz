import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

/// Particle spawned when enemy is destroyed
class EnemyDestroyParticle extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final Color color;
  final int count;
  double life = 0.4;
  late Vector2 velocity;
  double particleSize = 4;

  EnemyDestroyParticle({required Vector2 position, required this.color, this.count = 8}) : super(anchor: Anchor.center) {
    this.position = position;
    final rand = Random();
    final angle = (DateTime.now().microsecond % 6283) / 1000.0;
    final speed = 80.0 + (DateTime.now().microsecond % 120).toDouble();
    velocity = Vector2(
      (cos(angle) * speed).toDouble(),
      (sin(angle) * speed).toDouble(),
    );
    particleSize = 4.0 + (DateTime.now().microsecond % 4).toDouble();
    size = Vector2(particleSize * 2, particleSize * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity = velocity * 0.92;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 0.4).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withAlpha((alpha * 255).toInt());
    canvas.drawCircle(Offset(particleSize, particleSize), particleSize * alpha, paint);
  }
}