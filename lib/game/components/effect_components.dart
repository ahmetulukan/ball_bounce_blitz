import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors;
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'ball.dart';

/// Animated flames that follow the ball during fireball mode
class FireballFlames extends PositionComponent with HasGameRef<BallBounceGame> {
  final int flameLevel; // 1-5
  double _phase = 0;
  final Random _random = Random();

  FireballFlames({this.flameLevel = 3});

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 15;

    // Follow ball position
    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(position.x, position.y);

    // Draw animated flame tongues
    for (int i = 0; i < flameLevel; i++) {
      final baseAngle = -pi / 2; // pointing up
      final offset = (i - flameLevel / 2) * 0.3;
      final angle = baseAngle + offset;
      final length = 20.0 + _random.nextDouble() * 10 + sin(_phase + i) * 5;

      _drawFlame(canvas, angle, length, i);
    }

    canvas.restore();
  }

  void _drawFlame(Canvas canvas, double angle, double length, int index) {
    final colors = [
      const Color(0xFFFFEB3B),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
    ];

    final path = Path();
    
    // Flame shape
    path.moveTo(0, 0);
    path.quadraticBezierTo(
      cos(angle - 0.5) * length * 0.3,
      sin(angle - 0.5) * length * 0.3,
      cos(angle) * length,
      sin(angle) * length,
    );
    path.quadraticBezierTo(
      cos(angle + 0.5) * length * 0.3,
      sin(angle + 0.5) * length * 0.3,
      0,
      0,
    );

    final colorIndex = (index % colors.length);
    final paint = Paint()
      ..color = colors[colorIndex].withAlpha(180)
      ..style = PaintingStyle.fill;

    // Glow
    final glowPaint = Paint()
      ..color = colors[colorIndex].withAlpha(60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }
}

/// Kill streak counter that orbits the ball
class KillStreakOrbiter extends PositionComponent with HasGameRef<BallBounceGame> {
  int killCount;
  double _orbitAngle = 0;
  static const double orbitRadius = 22;
  static const double orbitSpeed = 3.0;

  KillStreakOrbiter({this.killCount = 0});

  @override
  void update(double dt) {
    super.update(dt);
    _orbitAngle += orbitSpeed * dt;

    // Follow ball
    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }
  }

  @override
  void render(Canvas canvas) {
    // Calculate orbiting position
    final x = cos(_orbitAngle) * orbitRadius * 0.8;
    final y = sin(_orbitAngle) * orbitRadius * 0.4 + orbitRadius * 0.5;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(x, y), 10, glowPaint);

    // Circle
    final bgPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(x, y), 8, bgPaint);

    // Number
    final textPainter = TextPainter(
      text: TextSpan(
        text: killCount.toString(),
        style: const TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }
}

/// Time-warp trail effect for slow-mo mode
class TimeWarpTrail extends PositionComponent {
  final Color color;
  double _life = 0.3;
  double _phase = 0;

  TimeWarpTrail({
    required Vector2 position,
    this.color = const Color(0xFF673AB7),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 20;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.3 * 150).round().clamp(0, 150);
    final radius = 8 * (_life / 0.3);

    // Purple vortex rings
    canvas.save();
    canvas.rotate(_phase);

    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (1 + i * 0.4);
      final ringAlpha = (alpha * (1 - i * 0.3)).round();
      final ringPaint = Paint()
        ..color = color.withAlpha(ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
    }

    canvas.restore();
  }
}