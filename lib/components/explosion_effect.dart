import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class ExplosionEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<ExplosionParticle> particles = [];
  double elapsed = 0;
  final double lifetime;
  final Color explosionColor;
  final double explosionScale;

  ExplosionEffect({
    required Vector2 position,
    required Color color,
    this.lifetime = 0.6,
    this.explosionScale = 1.0,
  })  : explosionColor = color,
        super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rand = Random();
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 3.14159 * 2 + rand.nextDouble() * 0.3;
      final speed = (100 + rand.nextDouble() * 120) * explosionScale;
      particles.add(ExplosionParticle(
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: (4 + rand.nextDouble() * 4) * explosionScale,
        rotationSpeed: rand.nextDouble() * 6,
        initialAngle: rand.nextDouble() * 6.28,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    for (final p in particles) {
      p.offset = Offset(p.offset.dx + p.velocity.x * dt, p.offset.dy + p.velocity.y * dt);
      p.velocity = p.velocity * 0.88;
      p.angle += p.rotationSpeed * dt;
    }
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / lifetime;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      canvas.save();
      canvas.translate(p.offset.dx, p.offset.dy);
      canvas.rotate(p.angle);
      final paint = Paint()
        ..color = explosionColor.withAlpha((alpha * 255).toInt())
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
      canvas.restore();
    }
  }
}

class ExplosionParticle {
  Offset offset = Offset.zero;
  Vector2 velocity;
  double size;
  double rotationSpeed;
  double angle;
  ExplosionParticle({
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required double initialAngle,
  }) : angle = initialAngle;
}
