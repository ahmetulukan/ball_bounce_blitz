import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

class Paddle extends PositionComponent {
  static const double paddleWidth = 100;
  static const double paddleHeight = 15;
  static const double speed = 500;

  late BallBounceGame gameRef;
  double _glowIntensity = 0;
  double _hitFlash = 0;
  int consecutiveHits = 0;

  Paddle() : super(
    position: Vector2(200, 350),
    size: Vector2(paddleWidth, paddleHeight),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  void move(double dx) {
    double newX = position.x + dx;
    newX = newX.clamp(paddleWidth / 2, 400 - paddleWidth / 2);
    position = Vector2(newX, position.y);
  }

  void onBallHit() {
    consecutiveHits++;
    _hitFlash = 1.0;
    _glowIntensity = 1.0;
    
    // Spawn hit particles
    gameRef.add(PaddleHitParticle(
      position: Vector2(position.x, position.y - paddleHeight / 2),
      color: _getHitColor(),
    ));
  }

  Color _getHitColor() {
    if (consecutiveHits >= 10) return const Color(0xFFFF5722); // Fire
    if (consecutiveHits >= 5) return const Color(0xFFFFEB3B); // Gold
    if (consecutiveHits >= 3) return const Color(0xFF03A9F4); // Blue
    return const Color(0xFFFFFFFF);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x = position.x.clamp(paddleWidth / 2, 400 - paddleWidth / 2);
    
    // Decay effects
    _hitFlash *= 0.9;
    _glowIntensity *= 0.95;
    
    if (_hitFlash < 0.01) _hitFlash = 0;
    if (_glowIntensity < 0.01) _glowIntensity = 0;
  }

  @override
  void render(Canvas canvas) {
    final baseColor = Color.lerp(
      const Color(0xFF2196F3),
      const Color(0xFFFF5722),
      (_glowIntensity * 0.5).clamp(0, 0.5),
    )!;

    // Outer glow
    if (_glowIntensity > 0.1) {
      final glowPaint = Paint()
        ..color = _getHitColor().withAlpha((_glowIntensity * 150).round())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * _glowIntensity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: paddleWidth + 8,
            height: paddleHeight + 8,
          ),
          const Radius.circular(8),
        ),
        glowPaint,
      );
    }

    // Hit flash overlay
    if (_hitFlash > 0.1) {
      final flashPaint = Paint()..color = _getHitColor().withAlpha((_hitFlash * 180).round());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: paddleWidth,
            height: paddleHeight,
          ),
          const Radius.circular(6),
        ),
        flashPaint,
      );
    }

    // Main paddle body
    final paddlePaint = Paint()..color = baseColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: paddleWidth,
          height: paddleHeight,
        ),
        const Radius.circular(6),
      ),
      paddlePaint,
    );

    // Top highlight stripe
    final highlightPaint = Paint()..color = Colors.white.withAlpha(120);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -paddleHeight / 4),
          width: paddleWidth - 10,
          height: 4,
        ),
        const Radius.circular(2),
      ),
      highlightPaint,
    );

    // Streak indicator (consecutive hits)
    if (consecutiveHits >= 3) {
      _renderStreakIndicator(canvas);
    }
  }

  void _renderStreakIndicator(Canvas canvas) {
    final streakColor = _getHitColor();
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${consecutiveHits}x',
        style: TextStyle(
          color: streakColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, paddleHeight / 2 + 4),
    );
  }

  void resetStreak() {
    consecutiveHits = 0;
    _hitFlash = 0;
    _glowIntensity = 0;
  }
}

class PaddleHitParticle extends PositionComponent {
  static const double particleLife = 0.3;
  static const double particleSpeed = 150;

  final Color color;
  double _life = particleLife;
  final Random _random = Random();
  Vector2 velocity = Vector2.zero();

  PaddleHitParticle({required Vector2 position, required this.color}) : super(position: position);

  @override
  Future<void> onLoad() async {
    final angle = _random.nextDouble() * pi - pi / 2;
    final speed = particleSpeed + _random.nextDouble() * 50;
    velocity = Vector2(cos(angle) * speed, sin(angle) * speed - 50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / particleLife * 255).round();
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, 3 * (_life / particleLife), paint);
  }
}