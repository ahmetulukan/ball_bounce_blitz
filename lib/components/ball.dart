import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';
import '../../services/audio_manager.dart';
import 'enemy.dart';
import 'paddle.dart';
import 'power_up.dart';
import 'barrier.dart';

class Ball extends PositionComponent with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  final Paddle paddle;
  final Function(int) onScore;
  final VoidCallback onLifeLost;
  final VoidCallback onGameOver;
  final dynamic gameScene;
  final bool isExtra;
  Vector2 velocity = Vector2.zero();
  static const double radius = 10;
  static const double baseSpeed = 200;
  double _speed = baseSpeed;
  bool _boosted = false;
  double _boostTimer = 0;
  bool _hasHitPaddleThisLaunch = false;
  static const double maxSpeed = 500;
  static const double minSpeed = 150;
  bool fireballActive = false;
  double _fireballTimer = 0;

  Ball({
    required this.paddle,
    required this.onScore,
    required this.onLifeLost,
    required this.onGameOver,
    required this.gameScene,
    this.isExtra = false,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    position = Vector2(gameSize.x / 2, isExtra ? gameSize.y * 0.6 : gameSize.y - 100);
    final angle = isExtra ? (Random().nextDouble() - 0.5) * pi / 2 : 0.0;
    velocity = Vector2(sin(angle) * _speed, -cos(angle) * _speed);
    size = Vector2(radius * 2, radius * 2);
    add(CircleHitbox(radius: radius));
  }

  void reset() {
    final gameSize = game.size;
    position = Vector2(gameSize.x / 2, gameSize.y - 100);
    _speed = baseSpeed;
    _boosted = false;
    _boostTimer = 0;
    _hasHitPaddleThisLaunch = false;
    velocity = Vector2(0, -_speed);
  }

  void boost() {
    _boosted = true;
    _boostTimer = 5;
    _prevSpeedForBoost = _speed;
    _speed = (baseSpeed * 1.5).clamp(minSpeed, maxSpeed);
    if (velocity.length > 0) {
      velocity = velocity.normalized() * _speed;
    } else {
      velocity = Vector2(0, -_speed);
    }
  }

  void activateFireball() {
    fireballActive = true;
    _fireballTimer = 6;
  }

  double _prevSpeedForBoost = baseSpeed;

  @override
  void update(double dt) {
    super.update(dt);

    if (_boosted) {
      _boostTimer -= dt;
      if (_boostTimer <= 0) {
        _boosted = false;
        _speed = (_prevSpeedForBoost + (_prevSpeedForBoost - baseSpeed) * 0.5).clamp(minSpeed, maxSpeed);
        if (velocity.length > 0) velocity = velocity.normalized() * _speed;
      }
    }

    if (fireballActive) {
      _fireballTimer -= dt;
      if (_fireballTimer <= 0) fireballActive = false;
    }

    if (magnetActive) {
      _applyMagnet(dt);
    }

    position += velocity * dt;

    // Wall bounces
    if (position.x <= radius) {
      velocity.x = _speed.abs();
      position.x = radius;
    }
    if (position.x >= game.size.x - radius) {
      velocity.x = -_speed.abs();
      position.x = game.size.x - radius;
    }
    if (position.y <= radius) {
      velocity.y = _speed.abs();
      position.y = radius;
    }
    if (position.y >= game.size.y - radius) {
      if (isExtra) {
        removeFromParent();
      } else {
        onLifeLost();
      }
    }

    // Paddle collision - single trigger per launch
    if (!_hasHitPaddleThisLaunch &&
        position.y + radius >= paddle.position.y - Paddle.paddleHeight / 2 &&
        position.y - radius <= paddle.position.y + Paddle.paddleHeight / 2 &&
        position.x >= paddle.position.x - paddle.currentWidth / 2 &&
        position.x <= paddle.position.x + paddle.currentWidth / 2 &&
        velocity.y > 0) {
      _bounceOffPaddle();
      _hasHitPaddleThisLaunch = true;
    }

    // Reset when ball goes above paddle
    if (position.y < paddle.position.y - Paddle.paddleHeight) {
      _hasHitPaddleThisLaunch = false;
    }
  }

  bool get isBoosted => _boosted;
  bool get magnetActive => (gameScene as dynamic)?.magnetActive == true;

  void _applyMagnet(double dt) {
    final dx = paddle.position.x - position.x;
    final dy = paddle.position.y - position.y;
    final distSq = dx * dx + dy * dy;
    if (distSq < 160000) {
      final norm = Vector2(dx, dy).normalized();
      velocity = velocity + norm * 400 * dt;
      if (velocity.length > 0) velocity = velocity.normalized() * _speed;
    }
  }

  void _bounceOffPaddle() {
    final hitPos = (position.x - paddle.position.x) / (paddle.currentWidth / 2);
    final angle = hitPos * pi / 3;
    final spd = _boosted ? (_speed * 1.2).clamp(minSpeed, maxSpeed) : _speed;
    
    final bool isCritical = paddle.isInCriticalZone(position.x);
    final int basePoints = isCritical ? 25 : 10;
    final double speedBonus = isCritical ? 8.0 : 5.0;
    
    velocity = Vector2(sin(angle) * spd, -cos(angle) * spd);
    onScore(basePoints);
    AudioManager.playHit();
    _speed = (_speed + speedBonus).clamp(minSpeed, maxSpeed);
    _normalizeVelocity();
  }

  void _normalizeVelocity() {
    if (velocity.length > 0) velocity = velocity.normalized() * _speed;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      other.takeHit(gameScene);
      // Fireball pierces through enemies without bouncing
      if (!fireballActive) {
        final dy = position.y - other.position.y;
        final dx = position.x - other.position.x;
        if (dy.abs() > dx.abs()) {
          velocity.y = -velocity.y;
        } else {
          velocity.x = -velocity.x;
        }
        _speed = (_speed + 2).clamp(minSpeed, maxSpeed);
      } else {
        // Fireball trail effect
        AudioManager.playExplosion();
      }
    } else if (other is PowerUp) {
      gameScene?.collectPowerUp(other.type);
      other.removeFromParent();
    } else if (other is Barrier) {
      other.takeHit(gameScene);
      if (intersectionPoints.isNotEmpty && velocity.length > 0) {
        final hitPoint = intersectionPoints.first;
        final dx = (hitPoint.x - other.position.x).abs();
        final dy = (hitPoint.y - other.position.y).abs();
        if (dx > dy) {
          velocity.x = -velocity.x;
        } else {
          velocity.y = -velocity.y;
        }
        _speed = (_speed * 0.95).clamp(minSpeed, maxSpeed);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Boost glow
    if (_boosted) {
      final glow = Paint()..color = const Color(0x60FF9800);
      canvas.drawCircle(Offset(radius, radius), radius + 5, glow);
    }

    // Fireball glow - orange-red fire effect
    if (fireballActive) {
      final fireGlowOuter = Paint()..color = const Color(0x60FF5722);
      canvas.drawCircle(Offset(radius, radius), radius + 8, fireGlowOuter);
      final fireGlowInner = Paint()..color = const Color(0x80FF9800);
      canvas.drawCircle(Offset(radius, radius), radius + 4, fireGlowInner);
    }

    // Main ball
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          isExtra ? const Color(0xFFCDDC39) : const Color(0xFFFFEB3B),
          isExtra ? const Color(0xFF827717) : const Color(0xFFFFA000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, radius * 2, radius * 2));
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Highlight
    final hiPaint = Paint()..color = Colors.white.withAlpha(120);
    canvas.drawCircle(Offset(radius * 0.55, radius * 0.55), radius * 0.3, hiPaint);

    // Extra ball ring
    if (isExtra) {
      final ringPaint = Paint()
        ..color = const Color(0xFFCDDC39)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(radius, radius), radius + 3, ringPaint);
    }
  }
}