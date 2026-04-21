import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class ParticleEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<Particle> particles = [];
  final double lifetime;
  double elapsed = 0;
  final Color particleColor;

  ParticleEffect({required Vector2 position, required Color color, this.lifetime = 0.5, int count = 12}) 
      : particleColor = color, super(position: position) {
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2;
      final speed = 80 + (DateTime.now().microsecond % 60);
      particles.add(Particle(
        offset: Offset.zero,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: particleColor,
        size: 4 + (i % 3) * 2,
      ));
    }
  }

  @override
  void update
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    for (final p in particles) {
      p.offset = Offset(p.offset.dx + p.velocity.x * dt, p.offset.dy + p.velocity.y * dt);
      p.velocity = p.velocity * 0.92;
    }
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in particles) {
      final opacity = (1 - elapsed / lifetime).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withAlpha((opacity * 255).toInt());
      canvas.drawCircle(p.offset, p.size * (1 - elapsed / lifetime), paint);
    }
  }
}

class Particle {
  Offset offset;
  Vector2 velocity;
  final Color color;
  double size;
  Particle({required this.offset, required this.velocity, required this.color, required this.size});
}
