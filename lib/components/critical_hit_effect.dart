import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class CriticalHitEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<_Spark> sparks = [];
  double elapsed = 0;
  static const double lifetime = 0.7;

  CriticalHitEffect({required Vector2 position}) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rand = Random();
    for (int i = 0; i < 20; i++) {
      final angle = rand.nextDouble() * 3.14159 * 2;
      final speed = 120 + rand.nextDouble() * 180;
      sparks.add(_Spark(
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: 3 + rand.nextDouble() * 5,
        color: i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFFF9800),
      ));
    }
    // Add star burst in 8 directions
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 3.14159 * 2;
      sparks.add(_Spark(
        velocity: Vector2(cos(angle) * 220, sin(angle) * 220),
        size: 6,
        color: const Color(0xFFFFFFFF),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    for (final s in sparks) {
      s.offset = Offset(s.offset.dx + s.velocity.x * dt, s.offset.dy + s.velocity.y * dt);
      s.velocity = s.velocity * 0.90;
    }
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / lifetime;
    final alpha = (1 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.5;

    for (final s in sparks) {
      final paint = Paint()..color = s.color.withAlpha((alpha * 255).toInt());
      canvas.drawCircle(s.offset, s.size * scale, paint);
    }

    if (progress < 0.3) {
      // Central flash
      final flashAlpha = ((0.3 - progress) / 0.3 * 255).toInt();
      final flashPaint = Paint()..color = Colors.white.withAlpha(flashAlpha);
      canvas.drawCircle(Offset.zero, 30 * progress * 3, flashPaint);
    }
  }
}

class _Spark {
  Offset offset = Offset.zero;
  Vector2 velocity;
  double size;
  Color color;
  _Spark({required this.velocity, required this.size, required this.color});
}
