import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';
import '../../services/audio_manager.dart';
import 'enemy.dart';
import 'paddle.dart';
import 'power_up.dart';

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

  Ball({required this.paddle, required this.onScore, required this.onLifeLost, required this.onGameOver, required this.gameScene, this.isExtra = false}) : super(anchor: Anchor.center);


  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    position = Vector2(gameSize.x / 2, isExtra ? gameSize.y * 0.6 : gameSize.y - 100);
    final angle = isExtra ? (Random().nextDouble() - 0.5) * pi / 2 : 0.0;
    velocity = Vector2(sin(angle) * _speed, -cos(angle) * _speed);
    size = Vector2(radius * 2, radius * 2);
    // Add circle hitbox for proper collision detection
    add(CircleHitbox(radius: radius));
  }

  void reset() {
    final gameSize = game.size;
    position = Vector2(gameSize.x / 2, gameSize.y - 100);
    _speed = baseSpeed;
    _boosted = false;
    _boostTimer = 0;
    velocity = Vector2(0, -_speed);
  }

  void boost() {
    _boosted = true;
    _boostTimer = 5;
    _prevSpeedForBoost = _speed;
    _speed = baseSpeed * 1.5;
    if (velocity.length > 0) {
      velocity = velocity.normalized() * _speed;
    } else {
      velocity = Vector2(0, -_speed);
    }
  }

  double _prevSpeedForBoost = baseSpeed;

  @override
  void update(double dt) {
    super.update(dt);

    if (_boosted) {
      _boostTimer -= dt;
      if (_boostTimer <= 0) {
        _boosted = false;
        _speed = (_prevSpeedForBoost + (_prevSpeedForBoost - baseSpeed) * 0.5).clamp(baseSpeed, baseSpeed + 150);
        if (velocity.length > 0) velocity = velocity.normalized() * _speed;
      }
    }

    if (magnetActive) {
      _applyMagnet(dt);
    }

    position += velocity * dt;

    if (position.x <= radius) {
      velocity.x = _speed.abs();
      position.x = radius;
    }
    if (position.x >= game.size.x - radius) {
      velocity.x = -_speed.abs();
      position.x = game.size.x - radius;
    }
    if (position.y <= radius) {
      // Bounce downwards when hitting the top edge.
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

    if (position.y + radius >= paddle.position.y - Paddle.paddleHeight / 2 &&
        position.y - radius <= paddle.position.y + Paddle.paddleHeight / 2 &&
        position.x >= paddle.position.x - paddle.currentWidth / 2 &&
        position.x <= paddle.position.x + paddle.currentWidth / 2 &&
        velocity.y > 0) {
      _bounceOffPaddle();
    }
  }

  double get scoreFromSpeed => (_speed - baseSpeed) / 5;
  bool get isBoosted => _boosted;
  bool get magnetActive => (gameScene as dynamic)?.magnetActive == true;

  void _applyMagnet(double dt) {
    final dx = paddle.position.x - position.x;
    final dy = paddle.position.y - position.y;
    final distSq = dx * dx + dy * dy;
    if (distSq < 160000) { // within 400px
      final norm = Vector2(dx, dy).normalized();
      velocity = velocity + norm * 400 * dt;
      if (velocity.length > 0) velocity = velocity.normalized() * _speed;
    }
  }

  void _bounceOffPaddle() {
    final hitPos = (position.x - paddle.position.x) / (paddle.currentWidth / 2);
    final angle = hitPos * pi / 3;
    final spd = _boosted ? _speed * 1.2 : _speed;
    velocity = Vector2(sin(angle) * spd, -cos(angle) * spd);
    onScore(10);
    AudioManager.playHit();
    _speed += 5;
    _normalizeVelocity();
  }

  void _normalizeVelocity() {
    final mag = velocity.length;
    if (mag > 0) velocity = velocity.normalized() * _speed;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      other.takeHit(gameScene);
    } else if (other is PowerUp) {
      gameScene?.collectPowerUp(other.type);
      other.removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = isExtra ? const Color(0xFFCDDC39) : const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(radius, radius), radius, paint);
    if (_boosted) {
      final glow = Paint()..color = const Color(0x80FF9800);
      canvas.drawCircle(Offset(radius, radius), radius + 4, glow);
    }
  }
}