import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Rainbow confetti for combo milestones
class RainbowExplosion {
  static void spawn(dynamic game, Vector2 position, int comboLevel) {
    final colors = [
      const Color(0xFFFF0000),
      const Color(0xFFFF7F00),
      const Color(0xFFFFFF00),
      const Color(0xFF00FF00),
      const Color(0xFF0000FF),
      const Color(0xFF8B00FF),
    ];

    final count = 12 + comboLevel * 2;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + Random().nextDouble() * 0.5;
      final speed = 80.0 + Random().nextDouble() * 120;
      final color = colors[i % colors.length];

      final particle = _RainbowParticle(
        position: position.clone(),
        velocity: Vector2(sin(angle), -cos(angle)) * speed,
        color: color,
        maxAge: 1.0 + Random().nextDouble() * 0.5,
      );
      game.add(particle);
    }
  }
}

class _RainbowParticle extends PositionComponent {
  Vector2 velocity;
  final Color color;
  double _age = 0;
  final double maxAge;
  double _rotation = 0;

  _RainbowParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.maxAge = 1.5,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity.y += 50 * dt;
    velocity *= 0.97;
    _rotation += dt * 6;
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 255).round().clamp(0, 255);
    final radius = 4.0 * ((maxAge - _age) / maxAge);

    canvas.save();
    canvas.rotate(_rotation);

    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius),
      paint,
    );
    canvas.restore();
  }
}

/// Screen flash overlay for big combos
class ScreenFlashOverlay extends PositionComponent {
  double _age = 0;
  final double maxAge;
  final Color color;

  ScreenFlashOverlay({required this.color, this.maxAge = 0.15})
      : super(priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 100).round().clamp(0, 100);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 400, 420),
      Paint()..color = color.withAlpha(alpha),
    );
  }
}

/// Wave bonus popup text
class WaveBonusText extends PositionComponent {
  final int wave;
  double _age = 0;
  final double maxAge = 1.5;
  double _vy = 0;

  WaveBonusText({required Vector2 position, required this.wave})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= 30 * dt;
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 255).round().clamp(0, 255);
    final scale = 1.0 + _age * 0.2;

    canvas.save();
    canvas.scale(scale);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '+${50 * wave} WAVE BONUS!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFF000000), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }
}