import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors;
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

/// Full-screen pulse that flashes when boss is hit
class BossHitFlash extends Component {
  final Color color;
  double _life = 0.2;
  late BallBounceGame gameRef;

  BossHitFlash({this.color = const Color(0xFFFF5722)});

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.2 * 60).round().clamp(0, 60);
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 420), paint);
  }
}

/// Enemy spawn portal effect
class SpawnPortal extends PositionComponent {
  final Color color;
  double _life = 0.5;
  double _phase = 0;

  SpawnPortal({
    required Vector2 position,
    this.color = const Color(0xFF9C27B0),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 10;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.5 * 200).round().clamp(0, 200);
    canvas.save();
    canvas.rotate(_phase);

    // Spiral arms
    for (int i = 0; i < 4; i++) {
      final angle = (i * pi / 2);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(
          cos(angle + 0.5) * 15,
          sin(angle + 0.5) * 15,
          cos(angle + 1) * 25,
          sin(angle + 1) * 25,
        );
      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(path, paint);
    }

    canvas.restore();

    // Center glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 15, glowPaint);
  }
}

/// Critical hit star burst effect
class CriticalHitBurst extends PositionComponent {
  final double maxAge = 0.3;
  double _age = 0;
  final Color color;

  CriticalHitBurst({
    required Vector2 position,
    this.color = const Color(0xFFFFD700),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;
    final radius = 30 * t;

    // Star rays
    canvas.save();
    canvas.rotate(_age * 5);

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final rayLength = radius * 1.5;
      final rayPaint = Paint()
        ..color = color.withAlpha(alpha.round())
        ..strokeWidth = 3 * (1 - t)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cos(angle) * radius, sin(angle) * radius),
        Offset(cos(angle) * rayLength, sin(angle) * rayLength),
        rayPaint,
      );
    }

    canvas.restore();
  }
}

/// Score bonus popup with multiplier highlight
class ScoreBonusPopup extends PositionComponent {
  final int bonusScore;
  final int multiplier;
  double _life = 1.2;
  double _vy = -60;
  double _scale = 1.0;

  ScoreBonusPopup({
    required super.position,
    required this.bonusScore,
    this.multiplier = 1,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy *= 0.96;
    _scale = 0.5 + (1.2 - _life) / 1.2 * 0.5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 1.2 * 255).round().clamp(0, 255);

    // "+X" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$bonusScore',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 18 * _scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 4),
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

    // Multiplier badge
    if (multiplier > 1) {
      final badgePainter = TextPainter(
        text: TextSpan(
          text: 'x$multiplier',
          style: TextStyle(
            color: const Color(0xFFFF5722).withAlpha(alpha),
            fontSize: 12 * _scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      badgePainter.layout();
      badgePainter.paint(
        canvas,
        Offset(-badgePainter.width / 2, textPainter.height / 2 + 2),
      );
    }
  }
}

/// Multiplier surge visual when combo reaches milestones
class MultiplierSurge extends PositionComponent {
  final int level; // 2=1.5x, 3=2x, 4=2.5x, 5=3x
  double _life = 0.6;
  double _phase = 0;

  MultiplierSurge({required super.position, required this.level});

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 15;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.6 * 200).round().clamp(0, 200);
    final pulseScale = 1.0 + sin(_phase) * 0.2;
    final size = 40 * pulseScale;

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha((alpha * 0.3).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset.zero, size, glowPaint);

    // Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, size, ringPaint);

    // Inner ring
    final innerPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withAlpha((alpha * 0.7).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, size * 0.6, innerPaint);
  }
}

/// Power-up collected sparkle burst
class PowerUpSparkle extends PositionComponent {
  final Color color;
  final double maxAge = 0.5;
  double _age = 0;
  final int sparkCount;
  final Random _random = Random();

  PowerUpSparkle({
    required Vector2 position,
    required this.color,
    this.sparkCount = 8,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;
    final scale = 1.0 + t * 0.5;

    for (int i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * pi;
      final dist = 20 * t * scale;
      final sparkPaint = Paint()
        ..color = color.withAlpha(alpha.round())
        ..strokeWidth = 2 * (1 - t)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cos(angle) * dist * 0.5, sin(angle) * dist * 0.5),
        Offset(cos(angle) * dist, sin(angle) * dist),
        sparkPaint,
      );
    }

    // Center flash
    if (t < 0.2) {
      final centerAlpha = ((0.2 - t) / 0.2 * 200).round().clamp(0, 200);
      final centerPaint = Paint()
        ..color = Colors.white.withAlpha(centerAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset.zero, 10 * (1 - t), centerPaint);
    }
  }
}

/// Enhanced power-up collection sparkle with trail
class PowerUpCollectSparkle extends PositionComponent {
  final Color primaryColor;
  final Color secondaryColor;
  final double maxAge = 0.6;
  double _age = 0;
  double _rotation = 0;

  PowerUpCollectSparkle({
    required Vector2 position,
    required this.primaryColor,
    Color? secondaryColor,
  }) : secondaryColor = secondaryColor ?? Colors.white,
       super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 8;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;

    // Rotating star burst
    canvas.save();
    canvas.rotate(_rotation);

    final starPoints = 6;
    final outerRadius = 25 * t;
    final innerRadius = 10 * t;

    // Draw star
    final path = Path();
    for (int i = 0; i < starPoints * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / starPoints);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final starPaint = Paint()..color = primaryColor.withAlpha(alpha.round());
    canvas.drawPath(path, starPaint);

    // Inner glow
    final glowPaint = Paint()
      ..color = secondaryColor.withAlpha((alpha * 0.6).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    canvas.restore();
  }
}

/// Trail particle for fast-moving objects
class MotionTrail extends PositionComponent {
  final Color color;
  final double length;
  final double maxAge;
  double _age = 0;
  final List<Vector2> _trailPositions = [];
  static const int maxTrail = 8;

  MotionTrail({
    required Vector2 position,
    required this.color,
    this.length = 0.15,
    this.maxAge = 0.3,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    
    // Add current position to trail
    _trailPositions.insert(0, position.clone());
    if (_trailPositions.length > maxTrail) {
      _trailPositions.removeLast();
    }
    
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_trailPositions.length < 2) return;
    
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final baseAlpha = (1.0 - t) * 150;

    for (int i = 0; i < _trailPositions.length - 1; i++) {
      final alpha = (baseAlpha * (1 - i / _trailPositions.length)).round().clamp(0, 255);
      final radius = (10 * (1 - i / _trailPositions.length)).clamp(1.0, 10.0);
      
      final paint = Paint()..color = color.withAlpha(alpha);
      canvas.drawCircle(
        Offset(_trailPositions[i].x - position.x, _trailPositions[i].y - position.y),
        radius,
        paint,
      );
    }
  }
}

/// Shimmer particle for special power-ups
class ShimmerParticle extends PositionComponent {
  final Color color;
  final double maxAge;
  double _age = 0;
  double _phase = 0;

  ShimmerParticle({
    required Vector2 position,
    required this.color,
    this.maxAge = 0.8,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _phase += dt * 10;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 200;
    final shimmer = (sin(_phase) * 0.3 + 0.7);

    // Diamond shape
    canvas.save();
    canvas.rotate(_phase * 0.5);

    final path = Path()
      ..moveTo(0, -8)
      ..lineTo(6, 0)
      ..lineTo(0, 8)
      ..lineTo(-6, 0)
      ..close();

    final paint = Paint()..color = color.withAlpha((alpha * shimmer).round());
    canvas.drawPath(path, paint);

    // Shine
    final shinePaint = Paint()
      ..color = Colors.white.withAlpha((alpha * 0.5 * shimmer).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, shinePaint);

    canvas.restore();
  }
}

/// Warning pulse for incoming hazards
class HazardWarningPulse extends Component {
  final Vector2 position;
  final Color color;
  final double maxAge;
  double _age = 0;
  double _pulsePhase = 0;

  HazardWarningPulse({
    required this.position,
    this.color = const Color(0xFFFF5722),
    this.maxAge = 1.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _pulsePhase += dt * 6;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1 - t) * 150;
    final radius = 20 + sin(_pulsePhase) * 8;

    // Warning circle
    final paint = Paint()
      ..color = color.withAlpha(alpha.round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - t);
    canvas.drawCircle(Offset(position.x, position.y), radius, paint);

    // Inner warning
    final innerPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(position.x, position.y), radius * 0.4, innerPaint);
  }
}

/// Combo timer bar visual
class ComboTimerBar extends PositionComponent {
  final double maxDuration;
  final double currentTime;
  final int comboLevel;
  double _phase = 0;

  ComboTimerBar({
    required super.position,
    required this.maxDuration,
    required this.currentTime,
    required this.comboLevel,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 8;
  }

  @override
  void render(Canvas canvas) {
    final remaining = (currentTime / maxDuration).clamp(0.0, 1.0);
    final barWidth = 80.0;
    final barHeight = 8.0;

    // Background
    final bgPaint = Paint()..color = const Color(0x88000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: barWidth, height: barHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Fill
    final fillWidth = barWidth * remaining;
    final fillColor = _getComboColor();
    final fillPaint = Paint()..color = fillColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, -barHeight / 2, fillWidth, barHeight),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // Pulsing glow at end
    if (remaining < 0.3) {
      final pulseAlpha = (sin(_phase) * 30 + 50).round().clamp(0, 80);
      final pulsePaint = Paint()
        ..color = fillColor.withAlpha(pulseAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(barWidth / 2 - fillWidth + barWidth / 2, 0),
        6,
        pulsePaint,
      );
    }
  }

  Color _getComboColor() {
    if (comboLevel >= 15) return const Color(0xFFFF1493);
    if (comboLevel >= 10) return const Color(0xFFFF5722);
    if (comboLevel >= 5) return const Color(0xFFFFEB3B);
    return const Color(0xFF4CAF50);
  }
}

/// Wave transition fade effect
class WaveTransitionFade extends Component {
  final double maxAge;
  double _age = 0;
  bool _fadingIn = true;

  WaveTransitionFade({this.maxAge = 0.5});

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    double alpha;
    if (_fadingIn) {
      alpha = t * 200;
      if (t >= 1.0) {
        _fadingIn = false;
        _age = 0;
      }
    } else {
      alpha = (1 - t) * 200;
    }

    final paint = Paint()..color = const Color(0xFF000000).withAlpha(alpha.round());
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 420), paint);
  }
}

/// Perfect clear bonus effect
class PerfectClearEffect extends PositionComponent {
  final double maxAge = 2.0;
  double _age = 0;
  double _phase = 0;

  PerfectClearEffect({required super.position}) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _phase += dt * 3;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = t < 0.2 ? t / 0.2 : (1 - (t - 0.2) / 0.8);

    // Star burst
    final scale = 1.0 + t * 0.5;
    final radius = 30 * scale;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((alpha * 100).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, radius * 1.5, glowPaint);

    // Rays
    canvas.save();
    canvas.rotate(_phase);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi;
      final rayLength = radius * (1.5 + t);
      final rayPaint = Paint()
        ..color = const Color(0xFFFFD700).withAlpha((alpha * 255).round())
        ..strokeWidth = 3 * (1 - t);
      canvas.drawLine(
        Offset(cos(angle) * radius, sin(angle) * radius),
        Offset(cos(angle) * rayLength, sin(angle) * rayLength),
        rayPaint,
      );
    }
    canvas.restore();

    // Center text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PERFECT!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha((alpha * 255).round()),
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
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

/// Barrier warning effect
class BarrierWarning extends PositionComponent {
  final Vector2 direction; // direction the barrier is moving
  double _life = 0.8;
  double _phase = 0;

  BarrierWarning({required super.position, required this.direction})
      : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 8;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.8 * 150).round().clamp(0, 150);
    final width = 60 * (1 - _life / 0.8) + 20;

    // Warning chevron
    final path = Path();
    path.moveTo(-width / 2, direction.y > 0 ? -8 : 8);
    path.lineTo(0, direction.y > 0 ? 8 : -8);
    path.lineTo(width / 2, direction.y > 0 ? -8 : 8);

    final paint = Paint()
      ..color = const Color(0xFFFFEB3B).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // Pulsing glow
    final pulseAlpha = (sin(_phase) * 30 + 50).round().clamp(0, 80);
    final glowPaint = Paint()
      ..color = const Color(0xFFFFEB3B).withAlpha(pulseAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);
  }
}