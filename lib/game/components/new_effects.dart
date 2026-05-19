import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors, LinearGradient;
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

/// Screen flash overlay for power-up feedback
class ScreenFlashOverlay extends PositionComponent {
  final Color color;
  final double maxAge;
  double _age = 0;

  ScreenFlashOverlay({
    required this.color,
    required this.maxAge,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 200);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 100;
    final paint = Paint()..color = color.withAlpha(alpha.round());
    canvas.drawRect(
      Rect.fromLTWH(-200, -200, 400, 400),
      paint,
    );
  }
}

/// Border glow effect for powerful power-ups
class BorderGlowEffect extends PositionComponent {
  final Color color;
  final double maxAge;
  final double thickness;
  double _age = 0;
  double _rotation = 0;

  BorderGlowEffect({
    required this.color,
    required this.maxAge,
    required this.thickness,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 200);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 2;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 180;
    final currentThickness = thickness * (1.0 - t * 0.5);

    final rect = Rect.fromLTWH(-200, -200, 400, 400);
    final paint = Paint()
      ..color = color.withAlpha(alpha.round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentThickness;
    
    canvas.drawRect(rect, paint);

    // Corner accents
    final cornerSize = 30 * (1.0 - t);
    final cornerPaint = Paint()
      ..color = color.withAlpha(alpha.round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentThickness * 0.8
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(-200, -200), Offset(-200 + cornerSize, -200), cornerPaint);
    canvas.drawLine(Offset(-200, -200), Offset(-200, -200 + cornerSize), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(200, -200), Offset(200 - cornerSize, -200), cornerPaint);
    canvas.drawLine(Offset(200, -200), Offset(200, -200 + cornerSize), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(-200, 200), Offset(-200 + cornerSize, 200), cornerPaint);
    canvas.drawLine(Offset(-200, 200), Offset(-200, 200 - cornerSize), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(200, 200), Offset(200 - cornerSize, 200), cornerPaint);
    canvas.drawLine(Offset(200, 200), Offset(200, 200 - cornerSize), cornerPaint);
  }
}

/// Slow motion overlay effect
class SlowMoOverlay extends PositionComponent {
  double _age = 0;
  static const double maxAge = 3.0;

  SlowMoOverlay() : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 200);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
  }

  @override
  void render(Canvas canvas) {
    final alpha = 60 + sin(_age * 8) * 20;
    final paint = Paint()..color = const Color(0xFF673AB7).withAlpha(alpha.round().clamp(0, 80));
    canvas.drawRect(Rect.fromLTWH(-200, -200, 400, 400), paint);
    
    // Chromatic aberration hint
    final edgePaint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha((alpha * 0.3).round().clamp(0, 30))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(-198, -198, 396, 396), edgePaint);
  }
}

/// Wave bonus text popup
class WaveBonusText extends PositionComponent {
  final int bonusScore;
  final double life;
  double _age = 0;
  double _vy = -40;

  WaveBonusText({
    required super.position,
    required this.bonusScore,
    this.life = 1.5,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.96;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final scale = 1.0 + (1.0 - _age / life) * 0.3;

    // Glow background
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha((alpha * 60).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 50 * scale, glowPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$bonusScore',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha((alpha * 255).round()),
          fontSize: 24 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Combo multiplier text that appears when multiplier increases
class ComboMultiplierPopup extends PositionComponent {
  final int multiplier;
  final double life;
  double _age = 0;
  double _vy = -30;
  double _pulsePhase = 0;

  ComboMultiplierPopup({
    required super.position,
    required this.multiplier,
    this.life = 1.2,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.95;
    _pulsePhase += dt * 10;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final pulse = 1.0 + sin(_pulsePhase) * 0.1;

    // Background glow
    final glowPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha((alpha * 80).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * pulse, height: 40 * pulse),
        Radius.circular(20 * pulse),
      ),
      glowPaint,
    );

    // Background
    final bgPaint = Paint()..color = const Color(0xFF1A1A2E).withAlpha((alpha * 220).round());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * pulse, height: 40 * pulse),
        Radius.circular(20 * pulse),
      ),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF4081).withAlpha((alpha * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * pulse, height: 40 * pulse),
        Radius.circular(20 * pulse),
      ),
      borderPaint,
    );

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x$multiplier',
        style: TextStyle(
          color: const Color(0xFFFF4081).withAlpha((alpha * 255).round()),
          fontSize: 20 * pulse,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Star burst effect for critical hits
class StarBurst extends PositionComponent {
  final double life;
  double _age = 0;
  double _rotation = 0;

  StarBurst({
    required super.position,
    this.life = 0.5,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 8;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;
    final radius = 20 + t * 40;

    canvas.save();
    canvas.rotate(_rotation);

    // Draw 8-pointed star
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * pi / 180;
      final r = i.isEven ? radius : radius * 0.4;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha.round().clamp(0, 255))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Inner glow
    final glowPaint = Paint()
      ..color = Colors.white.withAlpha((alpha * 0.5).round().clamp(0, 255))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    canvas.restore();
  }
}

/// Hit marker burst for enemy hits
class HitMarkerBurst extends PositionComponent {
  final Color color;
  final int rays;
  final double life;
  double _age = 0;

  HitMarkerBurst({
    required super.position,
    required this.color,
    this.rays = 6,
    this.life = 0.3,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 200;
    final length = 15 + t * 20;

    final paint = Paint()
      ..color = color.withAlpha(alpha.round().clamp(0, 255))
      ..strokeWidth = 2 * (1.0 - t)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rays; i++) {
      final angle = (i * 60) * pi / 180;
      final startX = cos(angle) * 5;
      final startY = sin(angle) * 5;
      final endX = cos(angle) * length;
      final endY = sin(angle) * length;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }
}

/// Power-up burst effect on collection
class PowerUpBurst extends PositionComponent {
  final Color color;
  final double life;
  double _age = 0;

  PowerUpBurst({
    required super.position,
    required this.color,
    this.life = 0.4,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 200;
    final radius = 5 + t * 40;

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withAlpha(alpha.round().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1.0 - t);
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner glow
    if (t < 0.5) {
      final glowPaint = Paint()
        ..color = color.withAlpha(((0.5 - t) / 0.5 * 100).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, radius * 0.5, glowPaint);
    }
  }
}

/// Power-up sparkle collection effect
class PowerUpCollectSparkle extends PositionComponent {
  final Color primaryColor;
  final Color secondaryColor;
  final double life;
  double _age = 0;
  final Random _random = Random(42);
  late List<_Sparkle> _sparkles;

  PowerUpCollectSparkle({
    required super.position,
    required this.primaryColor,
    required this.secondaryColor,
    this.life = 0.6,
  }) : super(anchor: Anchor.center) {
    _sparkles = List.generate(12, (i) => _Sparkle(
      angle: (i / 12) * 2 * pi,
      speed: 80 + _random.nextDouble() * 60,
      size: 2 + _random.nextDouble() * 3,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final s in _sparkles) {
      s.x += cos(s.angle) * s.speed * dt;
      s.y += sin(s.angle) * s.speed * dt;
      s.speed *= 0.92;
    }
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;

    for (int i = 0; i < _sparkles.length; i++) {
      final s = _sparkles[i];
      final color = i.isEven ? primaryColor : secondaryColor;
      final paint = Paint()
        ..color = color.withAlpha(alpha.round().clamp(0, 255))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(s.x, s.y), s.size * (1.0 - t * 0.5), paint);
    }
  }
}

class _Sparkle {
  double angle;
  double x = 0;
  double y = 0;
  double speed;
  double size;

  _Sparkle({required this.angle, required this.speed, required this.size});
}

/// Explosion effect for impacts
class ExplosionEffect extends PositionComponent {
  final Color color;
  final int count;
  final double speed;
  final double life;
  double _age = 0;
  late List<_ExplosionParticle> _particles;
  final Random _random = Random();

  ExplosionEffect({
    required super.position,
    required this.color,
    this.count = 8,
    this.speed = 100,
    this.life = 0.4,
  }) : super(anchor: Anchor.center) {
    _particles = List.generate(count, (i) => _ExplosionParticle(
      angle: _random.nextDouble() * 2 * pi,
      speed: speed * (0.5 + _random.nextDouble() * 0.8),
      size: 2 + _random.nextDouble() * 3,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    for (final p in _particles) {
      p.x += cos(p.angle) * p.speed * dt;
      p.y += sin(p.angle) * p.speed * dt;
      p.speed *= 0.88;
    }
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 255;

    for (final p in _particles) {
      final glowPaint = Paint()
        ..color = color.withAlpha(alpha.round().clamp(0, 255))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(p.x, p.y), p.size * (1.0 - t * 0.5), glowPaint);
      
      final paint = Paint()
        ..color = Colors.white.withAlpha((alpha * 0.7).round().clamp(0, 255));
      canvas.drawCircle(Offset(p.x, p.y), p.size * 0.5 * (1.0 - t * 0.5), paint);
    }
  }
}

class _ExplosionParticle {
  double angle;
  double x = 0;
  double y = 0;
  double speed;
  double size;

  _ExplosionParticle({required this.angle, required this.speed, required this.size});
}