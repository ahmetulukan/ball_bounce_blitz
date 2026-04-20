import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'paddle.dart';
import 'enemy.dart';
import 'power_up.dart';
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

    if (position.x - ballRadius <= 0) {
      position.x = ballRadius;
      velocity.x = velocity.x.abs();
    } else if (position.x + ballRadius >= 400) {
      position.x = 400 - ballRadius;
      velocity.x = -velocity.x.abs();
    }

    if (position.y - ballRadius <= 0) {
      position.y = ballRadius;
      velocity.y = velocity.y.abs();
    }

    if (position.y > 400 + ballRadius) {
      gameRef.loseLife();
      reset();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Paddle) {
      final paddleCenter = other.position.x;
      final diff = (position.x - paddleCenter) / (Paddle.paddleWidth / 2);
      final angle = diff * 0.7;
      velocity = Vector2(sin(angle), -cos(angle)) * speed;
      position.y = other.position.y - Paddle.paddleHeight / 2 - ballRadius;
    }

    if (other is Enemy) {
      other.destroy();
      if (isFireball) {
        speed = (speed + 20).clamp(baseSpeed, baseSpeed * 1.5);
        velocity = velocity.normalized() * speed;
      }
    }

    if (other is PowerUp) {
      gameRef.collectPowerUp(other.type);
      other.removeFromParent();
    }
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.fireball:
        isFireball = true;
        paint = Paint()..color = const Color(0xFFFF5722);
        Future.delayed(const Duration(seconds: 3), () {
          isFireball = false;
          paint = Paint()..color = const Color(0xFFFFFFFF);
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
    paint = Paint()..color = const Color(0xFFFFFFFF);
    _startMoving();
  }
}
