import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'paddle.dart';
import 'package:flame/game.dart';

class Ball extends PositionComponent with HasGameRef, TapCallbacks {
  final Paddle paddle;
  final void Function(dynamic enemy, Ball ball) onEnemyHit;
  final VoidCallback onLoseBall;

  Vector2 velocity = Vector2.zero();
  bool canHit = true;
  bool isLaunched = false;
  double _speedMultiplier = 1.0;
  final double _baseSpeed = 280;

  Ball({
    required this.paddle,
    required this.onEnemyHit,
    required this.onLoseBall,
    Vector2? position,
  }) : super(
    size: Vector2(14, 14),
    anchor: Anchor.center,
  ) {
    if (position != null) {
      this.position = position;
    } else {
      this.position = Vector2(paddle.position.x, paddle.position.y - 20);
    }
  }

  @override
  Future<void> onLoad() async {
    _resetVelocity();
  }

  void _resetVelocity() {
    final rand = Random();
    final angle = -pi / 2 + (rand.nextDouble() - 0.5) * 0.6;
    velocity = Vector2(
      cos(angle) * _baseSpeed * _speedMultiplier,
      sin(angle) * _baseSpeed * _speedMultiplier,
    );
    isLaunched = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (paddle.isMagnetActive) {
      paddle.applyMagnetForce(this, dt);
    }

    position = position + velocity * dt * _speedMultiplier;

    final gameSize = gameRef.size;

    if (position.x - size.x / 2 < 0) {
      position.x = size.x / 2;
      velocity.x = velocity.x.abs();
    } else if (position.x + size.x / 2 > gameSize.x) {
      position.x = gameSize.x - size.x / 2;
      velocity.x = -velocity.x.abs();
    }

    if (position.y - size.y / 2 < 0) {
      position.y = size.y / 2;
      velocity.y = velocity.y.abs();
    }

    if (position.y - size.y / 2 > gameSize.y) {
      onLoseBall();
      removeFromParent();
      return;
    }

    if (canHit) {
      final paddleRect = paddle.toRect();
      final ballRect = toRect();
      if (ballRect.overlaps(paddleRect)) {
        _bounceOffPaddle();
      }
    }

    if (velocity.length > 0) {
      final maxSpeed = _baseSpeed * _speedMultiplier * 1.5;
      if (velocity.length > maxSpeed) {
        velocity = velocity.normalized() * maxSpeed;
      }
    }
  }

  void _bounceOffPaddle() {
    final paddleX = paddle.position.x;
    final hitOffset = (position.x - paddleX) / (paddle.size.x / 2);
    final angle = hitOffset * (pi / 3);
    final speed = velocity.length;
    velocity = Vector2(sin(angle) * speed, -cos(angle) * speed);
    position.y = paddle.position.y - paddle.size.y / 2 - size.y / 2 - 1;
    canHit = false;
    Future.delayed(const Duration(milliseconds: 200), () => canHit = true);
  }

  void onHitEnemy() {
    canHit = false;
    Future.delayed(const Duration(milliseconds: 300), () => canHit = true);
  }

  void speedUp() {
    _speedMultiplier = 1.4;
    _applySpeed();
  }

  void slowDown() {
    _speedMultiplier = 0.65;
    _applySpeed();
  }

  void _applySpeed() {
    if (velocity.length > 0) {
      velocity = velocity.normalized() * _baseSpeed * _speedMultiplier;
    }
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = Color.fromARGB(80, 0, 188, 212)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 4, glowPaint);

    for (int i = 1; i <= 4; i++) {
      final trailAlpha = (1 - i / 5) * 0.4;
      final trailPaint = Paint()
        ..color = Color.fromARGB((trailAlpha * 255).toInt(), 0, 188, 212)
        ..style = PaintingStyle.fill;

      final trailSize = size.x * (1 - i / 6);
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), trailSize / 2, trailPaint);
    }

    final ballPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFFFFFFFF),
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, ballPaint);

    if (_speedMultiplier != 1.0) {
      final indicatorPaint = Paint()
        ..color = _speedMultiplier > 1
            ? Color.fromARGB(180, 255, 87, 34)
            : Color.fromARGB(180, 76, 175, 80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 3, indicatorPaint);
    }
  }

  Rect toRect() {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x,
      height: size.y,
    );
  }
}
