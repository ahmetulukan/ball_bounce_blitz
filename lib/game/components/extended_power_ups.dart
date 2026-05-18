import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../ball_bounce_game.dart';

enum PowerUpType { fireball, explosive, shield, speedUp, extraLife, magnet, multiball, slowmo, shrink, laser, energyShield, freezeTime, gravityWell }

// Extended power-up effect component
class EnergyShieldEffect extends PositionComponent {
  late BallBounceGame gameRef;
  double _rotationAngle = 0;
  double _pulsePhase = 0;
  double maxAge = 4.0;
  double age = 0;

  EnergyShieldEffect() : super();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    _rotationAngle += dt * 2;
    _pulsePhase += dt * 5;

    // Follow the ball
    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }

    if (age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fadeAlpha = (1.0 - age / maxAge).clamp(0.0, 1.0);
    final pulseScale = 1.0 + sin(_pulsePhase) * 0.1;

    canvas.save();
    canvas.translate(position.x, position.y);

    // Outer rotating ring
    final outerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((200 * fadeAlpha).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.save();
    canvas.rotate(_rotationAngle);
    canvas.drawCircle(Offset.zero, 25 * pulseScale, outerPaint);
    canvas.restore();

    // Inner rotating ring (opposite direction)
    final innerPaint = Paint()
      ..color = const Color(0xFF00FFFF).withAlpha((150 * fadeAlpha).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.rotate(-_rotationAngle * 1.5);
    canvas.drawCircle(Offset.zero, 20 * pulseScale, innerPaint);
    canvas.restore();

    // Shield particles
    for (int i = 0; i < 4; i++) {
      final angle = _rotationAngle + (i * pi / 2);
      final x = cos(angle) * 22 * pulseScale;
      final y = sin(angle) * 22 * pulseScale;
      final particlePaint = Paint()
        ..color = Colors.white.withAlpha((180 * fadeAlpha).round());
      canvas.drawCircle(Offset(x, y), 3 * fadeAlpha, particlePaint);
    }

    canvas.restore();
  }
}

// Freeze time effect - slows all enemies
class FreezeTimeEffect extends PositionComponent {
  late BallBounceGame gameRef;
  double maxAge = 3.0;
  double age = 0;
  double _flashTimer = 0;

  FreezeTimeEffect() : super();

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    _flashTimer += dt;

    if (age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fadeAlpha = (1.0 - age / maxAge).clamp(0.0, 1.0);

    // Ice crystal overlay
    final centerX = 200.0;
    final centerY = 200.0;

    final crystalPaint = Paint()
      ..color = const Color(0xFF81D4FA).withAlpha((60 * fadeAlpha).round())
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withAlpha((150 * fadeAlpha).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw ice crystal pattern
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * 3.14159 / 180 + _flashTimer * 0.5;
      final path = Path();
      path.moveTo(centerX, centerY);
      path.lineTo(centerX + cos(angle) * 200, centerY + sin(angle) * 200);
      canvas.drawPath(path, strokePaint);
    }

    // Central glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha((30 * fadeAlpha).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(Offset(centerX, centerY), 50, glowPaint);
  }
}