import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors, LinearGradient;
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'ball.dart';

/// Shrink aura effect when ball is in shrink mode
class ShrinkAura extends PositionComponent with HasGameRef<BallBounceGame> {
  double _phase = 0;
  double _life = 0;
  static const double maxAge = 0.5;
  bool _isShrinking = true;

  ShrinkAura();

  @override
  void update(double dt) {
    super.update(dt);

    // Follow ball
    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }

    // Pulse effect
    _phase += dt * 8;

    // If ball isn't shrunk, fade out
    if (gameRef.ball != null && gameRef.ball.speed > Ball.baseSpeed * 1.5) {
      _isShrinking = true;
      _life = 0;
    } else {
      _isShrinking = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isShrinking) return;

    final alpha = 100 + sin(_phase) * 30;

    // Concentric shrink rings
    for (int i = 0; i < 3; i++) {
      final radius = 15.0 + i * 8 + sin(_phase + i) * 3;
      final ringPaint = Paint()
        ..color = const Color(0xFF8BC34A).withAlpha(alpha.round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 - i * 0.5;
      canvas.drawCircle(Offset.zero, radius, ringPaint);
    }

    // Arrow indicators pointing inward
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi + _phase * 0.5;
      final arrowDist = 18 + sin(_phase * 2 + i) * 3;
      final x = cos(angle) * arrowDist;
      final y = sin(angle) * arrowDist;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 2);

      final path = Path()
        ..moveTo(0, -5)
        ..lineTo(4, 3)
        ..lineTo(-4, 3)
        ..close();

      final paint = Paint()
        ..color = const Color(0xFF8BC34A).withAlpha((alpha * 0.7).round());
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
}

/// Critical hit text popup
class CriticalHitText extends PositionComponent {
  final double maxAge = 0.8;
  double _age = 0;
  double _vy = -80;

  CriticalHitText({required super.position}) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.95;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;
    final scale = 0.5 + (1 - t) * 0.8;

    // CRITICAL! text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CRITICAL!',
        style: TextStyle(
          color: const Color(0xFFFF1493).withAlpha(alpha.round()),
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFFFFD700), blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}

/// Score multiplier display that follows the ball
class BallMultiplierBadge extends PositionComponent with HasGameRef<BallBounceGame> {
  final int multiplier;
  double _phase = 0;
  static const double orbitRadius = 28;

  BallMultiplierBadge({required this.multiplier});

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 2;

    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }
  }

  @override
  void render(Canvas canvas) {
    final angle = _phase;
    final x = cos(angle) * orbitRadius * 0.7;
    final y = sin(angle) * orbitRadius * 0.4 + orbitRadius * 0.5;

    // Background pill
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: 24, height: 14),
      const Radius.circular(7),
    );
    final bgPaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawRRect(rrect, bgPaint);

    // Multiplier text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x${_getMultiplierValue()}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  int _getMultiplierValue() {
    if (multiplier >= 4) return 3;
    if (multiplier >= 3) return 2;
    if (multiplier >= 2) return 1;
    return 1;
  }
}

/// Achievement unlock celebration
class AchievementUnlock extends PositionComponent {
  final String title;
  final String icon;
  final String description;
  double _life = 3.0;
  double _phase = 0;
  static const double maxAge = 3.0;

  AchievementUnlock({
    required super.position,
    required this.title,
    required this.icon,
    required this.description,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 2;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / maxAge).clamp(0.0, 1.0);
    final alpha = t > 0.8 ? (1.0 - (t - 0.8) / 0.2) : (t < 0.2 ? t / 0.2 : 1.0);
    final slideIn = t > 0.9 ? (1.0 - (t - 0.9) / 0.1) * 100 : 0.0;

    // Position based on slide-in state
    final yOffset = -slideIn;
    canvas.save();
    canvas.translate(0, yOffset);

    // Background card
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(200, 100), width: 280, height: 70),
      const Radius.circular(12),
    );
    final bgPaint = Paint()..color = const Color(0xFF1A1A2E).withAlpha((alpha * 230).round());
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((alpha * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: const TextStyle(fontSize: 28),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, const Offset(60 - 14, 100 - 14));

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 255).round()),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, const Offset(90, 75));

    // Description
    final descPainter = TextPainter(
      text: TextSpan(
        text: description,
        style: TextStyle(
          color: Colors.white70.withAlpha((alpha * 200).round()),
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    descPainter.layout();
    descPainter.paint(canvas, const Offset(90, 95));

    // Shine effect
    if (t > 0.7) {
      final shineAlpha = ((t - 0.7) / 0.3 * 100).round().clamp(0, 100);
      final shinePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(shineAlpha)
        ..shader = LinearGradient(
          colors: [
            const Color(0x00FFFFFF),
            const Color(0xFFFFFFFF).withAlpha(shineAlpha),
            const Color(0x00FFFFFF),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCenter(center: const Offset(200, 100), width: 280, height: 70));
      canvas.drawRRect(rrect, shinePaint);
    }

    canvas.restore();
  }
}

/// Multi-kill announcement (2x, 3x, 4x kills in quick succession)
class MultiKillAnnouncement extends PositionComponent {
  final int killCount; // 2, 3, or 4
  double _life = 2.0;
  double _phase = 0;

  MultiKillAnnouncement({
    required super.position,
    required this.killCount,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 3;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_life / 2.0).clamp(0.0, 1.0);
    final alpha = t > 0.8 ? (1.0 - (t - 0.8) / 0.2) : t;
    final scale = 0.6 + (1 - t) * 0.4;

    final colors = {
      2: const Color(0xFF4CAF50),
      3: const Color(0xFF2196F3),
      4: const Color(0xFFFF1493),
    };
    final color = colors[killCount.clamp(2, 4)] ?? const Color(0xFFFFD700);

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 100).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset.zero, 40 * scale, glowPaint);

    // Text
    final killText = killCount == 4 ? 'MEGA KILL!' : '${killCount}x KILL!';
    final textPainter = TextPainter(
      text: TextSpan(
        text: killText,
        style: TextStyle(
          color: color.withAlpha((alpha * 255).round()),
          fontSize: 24 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFF000000), blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}