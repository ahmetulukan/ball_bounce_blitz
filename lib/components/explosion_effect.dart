import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class ExplosionEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<ExplosionParticle> particles = [];
  double elapsed = 0;
  final double lifetime;
  final Color explosionColor;
  final double scale;

  ExplosionEffect({
    required Vector2 position,
    required Color color,
    this.lifetime = 0.6,
    this.scale = 1.0,
  })  : explosionColor = color,
        super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rand = Random();
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 3.14159 * 2 + rand.nextDouble() * 0.3;
      final speed = (100 + rand.nextDouble() * 120) * scale;
      particles.add(ExplosionParticle(
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: (4 + rand.nextDouble() * 4) * scale,
        rotationSpeed: rand.nextDouble() * 6,
        initialAngle: rand.nextDouble() * 6.28,
      ));
    }
    // Ring burst
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 3.14159 * 2;
      final speed = (60 + rand.nextDouble() * 40) * scale;
      particles.add(ExplosionParticle(
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: (3 + rand.nextDouble() * 2) * scale,
        rotationSpeed: 0,
        initialAngle: 0,
        isRing: true,
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
      if (p.isRing) {
        final paint = Paint()
          ..color = explosionColor.withAlpha((alpha * 200).toInt())
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.size * 0.5;
        canvas.drawCircle(p.offset, p.size * 1.5 * (1 + progress * 0.5), paint);
      } else {
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

    // Central flash
    if (progress < 0.2) {
      final flashAlpha = ((0.2 - progress) / 0.2 * 0.6).clamp(0.0, 0.6);
      final flashPaint = Paint()..color = Colors.white.withAlpha((flashAlpha * 255).toInt());
      canvas.drawCircle(Offset.zero, 30 * scale * (1 - progress * 2), flashPaint);
    }
  }
}

class ExplosionParticle {
  Offset offset = Offset.zero;
  Vector2 velocity;
  double size;
  double rotationSpeed;
  double angle;
  final bool isRing;
  ExplosionParticle({
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required this.initialAngle,
    this.isRing = false,
  }) : angle = initialAngle;
}

// Ball reference for radius - imported from ball.dart
class _BallRef {
  static const double radius = 10.0;
}
