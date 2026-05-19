import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

/// Charge shot mechanic - hold to charge shot power
class ChargeShotSystem extends Component with HasGameReference<BallBounceGame> {
  bool _isCharging = false;
  double _chargeLevel = 0; // 0 to 1
  static const double maxCharge = 1.5; // seconds to full charge
  double _chargeTimer = 0;

  // Charge state
  bool get isCharging => _isCharging;
  double get chargeLevel => _chargeLevel;

  @override
  void update(double dt) {
    super.update(dt);

    if (_isCharging && game.ball != null) {
      _chargeTimer += dt;
      _chargeLevel = (_chargeTimer / maxCharge).clamp(0.0, 1.0);

      // Visual feedback on paddle
      game.paddle.chargeLevel = _chargeLevel;
    }
  }

  void startCharging() {
    if (game.isPaused || game.isGameOver) return;
    _isCharging = true;
    _chargeTimer = 0;
    _chargeLevel = 0;
  }

  void releaseChargedShot() {
    if (!_isCharging) return;
    _isCharging = false;

    if (_chargeLevel > 0.3 && game.ball != null) {
      // Fire a charged shot - speed boost based on charge
      final speedBoost = 1.0 + _chargeLevel * 0.8;
      final currentSpeed = game.ball.speed;
      game.ball.speed = (currentSpeed * speedBoost).clamp(currentSpeed, currentSpeed * 1.8);
      game.ball.velocity = game.ball.velocity.normalized() * game.ball.speed;

      // Visual burst
      game.add(ChargeShotFlash(
        position: game.ball.position.clone(),
        intensity: _chargeLevel,
      ));

      // Screen shake on full charge
      if (_chargeLevel > 0.8) {
        game.screenShake.shake(intensity: 6 * _chargeLevel, duration: 0.2);
      }

      game.playSound('powerup');
    }

    _chargeTimer = 0;
    _chargeLevel = 0;
    game.paddle.chargeLevel = 0;
  }

  void cancelCharge() {
    _isCharging = false;
    _chargeTimer = 0;
    _chargeLevel = 0;
    game.paddle.chargeLevel = 0;
  }
}

/// Charge shot flash effect
class ChargeShotFlash extends PositionComponent {
  final double intensity;
  double _life = 0.3;

  ChargeShotFlash({required Vector2 position, required this.intensity})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.3 * 200).round().clamp(0, 255);
    final radius = (1 - _life / 0.3) * 30 * intensity + 10;

    final glowPaint = Paint()
      ..color = Color(0xFFFF9800).withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius, glowPaint);

    final ringPaint = Paint()
      ..color = Color(0xFFFFFFFF).withAlpha((alpha * 0.8).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, radius * 1.5, ringPaint);
  }
}

/// Target indicator showing predicted ball trajectory
class TargetIndicator extends PositionComponent with HasGameReference<BallBounceGame> {
  final int segments;
  final double maxLength;
  double _opacity = 0;

  TargetIndicator({
    this.segments = 5,
    this.maxLength = 150,
  });

  @override
  void update(double dt) {
    super.update(dt);

    if (game.ball == null || game.isPaused || game.isGameOver) {
      _opacity = 0;
      return;
    }

    // Only show when ball is moving down (about to bounce on paddle)
    final ball = game.ball!;
    if (ball.velocity.y > 0) {
      _opacity = (_opacity + dt * 3).clamp(0, 0.6);
    } else {
      _opacity = (_opacity - dt * 5).clamp(0, 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity < 0.01 || game.ball == null) return;

    final ball = game.ball!;
    final paddle = game.paddle;

    // Predict bounce point on paddle
    final predictedY = paddle.position.y - 15; // paddle top
    final ballY = ball.position.y;

    if (ballY >= predictedY - 50) {
      // Draw trajectory prediction
      final vel = ball.velocity;
      final speed = vel.length;

      // Simple bounce prediction
      var pos = ball.position.clone();
      var dir = vel.normalized();

      for (int i = 0; i < segments; i++) {
        final alpha = ((segments - i) / segments * _opacity * 150).round().clamp(0, 150);

        // Draw dot
        final dotPaint = Paint()
          ..color = const Color(0xFF00BCD4).withAlpha(alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(
          Offset(pos.x - game.size.x / 2, pos.y - game.size.y / 2),
          3 - i * 0.4,
          dotPaint,
        );

        // Move along trajectory
        final step = maxLength / segments;
        pos += dir * step;

        // Check paddle collision
        if (pos.y >= predictedY) {
          pos.y = predictedY;
          dir = Vector2(dir.x, -dir.y.abs());
        }

        // Wall bounces
        if (pos.x <= 10 || pos.x >= 390) {
          dir = Vector2(-dir.x, dir.y);
        }
      }
    }
  }
}