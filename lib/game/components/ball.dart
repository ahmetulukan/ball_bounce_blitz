import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'paddle.dart';
import 'enemy.dart';
import 'power_up.dart';
import 'barrier.dart';
import 'particles/explosion_particle.dart';
import 'particles/trail_particle.dart';
import '../ball_bounce_game.dart';

class Ball extends CircleComponent with CollisionCallbacks {
  static const double ballRadius = 10;
  static const double baseSpeed = 300;

  late Paddle paddle;
  late BallBounceGame gameRef;
  Vector2 velocity = Vector2.zero();
  double speed = baseSpeed;
  bool isFireball = false;
  bool isShielded = false;
  double _shieldAngle = 0;
  double _bounceScale = 1.0; // for bounce animation
  double _trailTimer = 0;

  Ball({required this.paddle, required this.gameRef}) : super(
    radius: ballRadius,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    _startMoving();
  }

  void _startMoving() {
    final random = Random();
    final angle = random.nextDouble() * 0.5 - 0.25;
    velocity = Vector2(sin(angle), -cos(angle)) * speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Bounce animation decay
    if (_bounceScale != 1.0) {
      _bounceScale = 1.0 + (_bounceScale - 1.0) * 0.85;
      if ((_bounceScale - 1.0).abs() < 0.01) _bounceScale = 1.0;
    }

    // Shield rotation
    if (isShielded) {
      _shieldAngle += dt * 4;
    }

    // Ball trail
    _trailTimer += dt;
    if (_trailTimer >= 0.03) {
      _trailTimer = 0;
      _spawnTrail();
    }

    if (position.x - ballRadius <= 0) {
      position.x = ballRadius;
      velocity.x = velocity.x.abs();
      _applyBounceEffect();
    } else if (position.x + ballRadius >= 400) {
      position.x = 400 - ballRadius;
      velocity.x = -velocity.x.abs();
      _applyBounceEffect();
    }

    if (position.y - ballRadius <= 0) {
      position.y = ballRadius;
      velocity.y = velocity.y.abs();
      _applyBounceEffect();
    }

    if (position.y > 400 + ballRadius) {
      gameRef.loseLife();
      reset();
    }
  }

  void _spawnTrail() {
    final trailColor = isFireball
        ? const Color(0xFFFF5722)
        : isShielded
            ? const Color(0xFF03A9F4)
            : const Color(0xFFFFFFFF);
    final trail = TrailParticle(
      position: position.clone(),
      velocity: Vector2.zero(),
      color: trailColor,
      life: 0.25,
      particleRadius: isFireball ? 5 : 3,
    );
    gameRef.add(trail);
  }

  void _applyBounceEffect() {
    _bounceScale = 1.3;
    // Spawn small particle burst on wall bounce
    if (isFireball) {
      gameRef.add(ExplosionEffect(
        position: position.clone(),
        color: const Color(0xFFFF5722),
        count: 4,
        speed: 80,
      ));
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) async {
    super.onCollision(intersectionPoints, other);

    if (other is Paddle) {
      paddle.onBallHit();
      final paddleCenter = other.position.x;
      final diff = (position.x - paddleCenter) / (Paddle.paddleWidth / 2);
      final angle = diff * 0.7;
      velocity = Vector2(sin(angle), -cos(angle)) * speed;
      position.y = other.position.y - Paddle.paddleHeight / 2 - ballRadius;
      _applyBounceEffect();
      gameRef.playSound('bounce');
    }

    if (other is Enemy) {
      final destroyed = other.takeHit();
      
      // Bounce ball away from enemy
      final bounceDir = (position - other.position).normalized();
      velocity = bounceDir * speed;
      _applyBounceEffect();
      
      if (destroyed) {
        gameRef.comboSystem.onEnemyDestroyed(other);
        gameRef.playSound('hit');
      } else {
        // Heavy enemy hit but not destroyed - smaller effect
        gameRef.add(ExplosionEffect(
          position: other.position.clone(),
          color: Enemy.getColor(other.color),
          count: 4,
          speed: 100,
        ));
        gameRef.playSound('hit');
      }
      
      if (isFireball) {
        speed = (speed + 20).clamp(baseSpeed, baseSpeed * 1.5);
        velocity = velocity.normalized() * speed;
      }
    }

    if (other is PowerUp) {
      gameRef.collectPowerUp(other.type);
      gameRef.playSound('powerup');
      other.removeFromParent();
    }

    if (other is Barrier) {
      // Bounce off barrier
      final relPos = position - other.position;
      if (relPos.y.abs() > other.size.x / 2) {
        // Vertical barrier hit
        velocity.y = -velocity.y;
        position.y = other.position.y + (velocity.y > 0 ? -1 : 1) * (ballRadius + other.size.y / 2);
      } else {
        // Horizontal barrier hit
        velocity.x = -velocity.x;
        position.x = other.position.x + (velocity.x > 0 ? -1 : 1) * (ballRadius + other.size.x / 2);
      }
      _applyBounceEffect();
      gameRef.playSound('bounce');
      
      // Barrier hit effect
      gameRef.add(ExplosionEffect(
        position: position.clone(),
        color: const Color(0xFF00BCD4),
        count: 5,
        speed: 80,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // Shield ring effect
    if (isShielded) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF03A9F4).withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, ballRadius + 6, shieldPaint);
      
      // Rotating shield arcs
      for (int i = 0; i < 3; i++) {
        final arcAngle = _shieldAngle + (i * 2 * pi / 3);
        final arcPaint = Paint()
          ..color = const Color(0xFF03A9F4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: ballRadius + 8),
          arcAngle,
          pi / 2,
          false,
          arcPaint,
        );
      }
    }
    
    // Fireball glow
    if (isFireball) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF5722).withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, ballRadius + 4, glowPaint);
    }

    // Main ball
    final ballPaint = Paint()..color = isFireball ? const Color(0xFFFF5722) : const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, ballRadius * _bounceScale, ballPaint);
    
    // Inner highlight
    final highlightPaint = Paint()..color = Colors.white.withAlpha(180);
    canvas.drawCircle(Offset(-ballRadius * 0.3, -ballRadius * 0.3), ballRadius * 0.3, highlightPaint);
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.fireball:
        isFireball = true;
        Future.delayed(const Duration(seconds: 3), () {
          isFireball = false;
        });
        break;
      case PowerUpType.explosive:
        gameRef.triggerExplosion(position);
        break;
      case PowerUpType.shield:
        isShielded = true;
        Future.delayed(const Duration(seconds: 5), () {
          isShielded = false;
        });
        break;
      case PowerUpType.speedUp:
        speed = (speed * 1.3).clamp(baseSpeed, baseSpeed * 2);
        velocity = velocity.normalized() * speed;
        Future.delayed(const Duration(seconds: 4), () {
          speed = (speed / 1.3).clamp(baseSpeed, baseSpeed * 2);
          velocity = velocity.normalized() * speed;
        });
        break;
      case PowerUpType.extraLife:
        gameRef.lives += 1;
        break;
    }
  }

  void reset() {
    position = Vector2(200, 200);
    isFireball = false;
    isShielded = false;
    speed = baseSpeed;
    _bounceScale = 1.0;
    _startMoving();
  }
}
