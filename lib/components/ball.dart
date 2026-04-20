import 'dart:math';
import 'package:flame/components.dart';
import '../../game/game.dart';
import 'paddle.dart';

class Ball extends PositionComponent with HasGameRef<BallBounceBlitzGame> {
  final Paddle paddle;
  final Function(int) onScore;
  final VoidCallback onGameOver;
  Vector2 velocity = Vector2.zero();
  static const double radius = 10;
  static const double baseSpeed = 200;
  double _speed = baseSpeed;

  Ball({required this.paddle, required this.onScore, required this.onGameOver}) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final gameSize = gameRef.size;
    position = Vector2(gameSize.x / 2, gameSize.y - 100);
    velocity = Vector2(0, -_speed);
    size = Vector2(radius * 2, radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Wall bounce
    if (position.x <= radius || position.x >= gameRef.size.x - radius) {
      velocity.x *= -1;
      position.x = position.x.clamp(radius, gameRef.size.x - radius);
    }
    // Top bounce
    if (position.y <= radius) {
      velocity.y *= -1;
      position.y = radius;
    }
    // Bottom = game over
    if (position.y >= gameRef.size.y - radius) {
      onGameOver();
    }

    // Paddle collision
    if (position.y + radius >= paddle.position.y - Paddle.height / 2 &&
        position.y - radius <= paddle.position.y + Paddle.height / 2 &&
        position.x >= paddle.position.x - Paddle.width / 2 &&
        position.x <= paddle.position.x + Paddle.width / 2 &&
        velocity.y > 0) {
      velocity.y *= -1;
      onScore(10);
      _speed += 5; // Gradually increase speed
      _adjustVelocityFromPaddleHit();
    }
  }

  void _adjustVelocityFromPaddleHit() {
    final hitPos = (position.x - paddle.position.x) / (Paddle.width / 2);
    final angle = hitPos * pi / 3; // Max 60 degree angle
    velocity = Vector2(sin(angle) * _speed, -cos(angle) * _speed);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }
}