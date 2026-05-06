import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Chain lightning effect that connects enemies during fireball attacks
class ChainLightning extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  final double life;
  final Color color;
  double _age = 0;

  ChainLightning({
    required this.start,
    required this.end,
    this.life = 0.3,
    this.color = const Color(0xFF00E5FF),
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
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final progress = _age / life;

    // Generate jagged lightning path
    final path = _generateLightningPath(start, end);
    
    // Glow layer
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 100).round())
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Core layer
    final corePaint = Paint()
      ..color = color.withAlpha((alpha * 255).round())
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, corePaint);

    // Bright core
    final brightPaint = Paint()
      ..color = Colors.white.withAlpha((alpha * 200).round())
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, brightPaint);

    // Start and end sparks
    if (alpha > 0.3) {
      _drawSpark(canvas, start, alpha);
      _drawSpark(canvas, end, alpha);
    }
  }

  Path _generateLightningPath(Vector2 start, Vector2 end) {
    final path = Path();
    path.moveTo(start.x, start.y);

    final segments = 6;
    final dx = (end.x - start.x) / segments;
    final dy = (end.y - start.y) / segments;
    final length = (end - start).length;
    final jitter = length * 0.15;

    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final x = start.x + dx * i + (Random().nextDouble() - 0.5) * jitter * 2;
      final y = start.y + dy * i + (Random().nextDouble() - 0.5) * jitter * 2;
      
      // Slight curve
      if (i < segments - 1) {
        final cx = x + (Random().nextDouble() - 0.5) * jitter;
        final cy = y + (Random().nextDouble() - 0.5) * jitter;
        path.quadraticBezierTo(cx, cy, x, y);
      } else {
        path.lineTo(end.x, end.y);
      }
    }
    return path;
  }

  void _drawSpark(Canvas canvas, Vector2 pos, double alpha) {
    final sparkPaint = Paint()
      ..color = Colors.white.withAlpha((alpha * 255).round());
    canvas.drawCircle(Offset(pos.x, pos.y), 4 * alpha, sparkPaint);

    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 150).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(pos.x, pos.y), 8 * alpha, glowPaint);
  }
}

/// Magnet field visual effect
class MagnetField extends PositionComponent {
  final double radius;
  final double life;
  double _age = 0;
  double _rotation = 0;

  MagnetField({
    required super.position,
    this.radius = 60,
    this.life = 2.0,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 4;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fade = (1.0 - _age / life).clamp(0.0, 1.0);
    final pulse = 1.0 + sin(_rotation * 2) * 0.1;

    // Outer glow ring
    final glowPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha((fade * 60).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, radius * pulse, glowPaint);

    // Magnetic field lines
    for (int i = 0; i < 8; i++) {
      final angle = _rotation + (i * pi / 4);
      final innerR = radius * 0.4;
      final outerR = radius * 0.9;

      final path = Path();
      
      // Field line curving in
      final startX = cos(angle) * outerR;
      final startY = sin(angle) * outerR;
      final endX = cos(angle + pi * 0.1) * innerR;
      final endY = sin(angle + pi * 0.1) * innerR;
      final cpX = cos(angle + pi * 0.05) * (innerR + 15);
      final cpY = sin(angle + pi * 0.05) * (innerR + 15);

      path.moveTo(startX, startY);
      path.quadraticBezierTo(cpX, cpY, endX, endY);

      final linePaint = Paint()
        ..color = const Color(0xFFE91E63).withAlpha((fade * 180).round())
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);
    }

    // Inner core
    final corePaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha((fade * 120).round());
    canvas.drawCircle(Offset.zero, 15 * pulse, corePaint);

    // Core bright spot
    final spotPaint = Paint()
      ..color = Colors.white.withAlpha((fade * 200).round());
    canvas.drawCircle(Offset.zero, 6 * pulse, spotPaint);
  }
}

/// Critical hit text effect
class CriticalHitText extends PositionComponent {
  final double life;
  double _age = 0;
  double _vy = -60;
  double _rotation = 0;

  CriticalHitText({
    required super.position,
    this.life = 0.8,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.92;
    _rotation += dt * 3;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final scale = 1.0 + (1.0 - _age / life) * 0.5;

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(_rotation * 0.3);
    canvas.scale(scale);

    // Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x88000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CRITICAL!',
        style: TextStyle(
          color: const Color(0xFFFF4444).withAlpha((alpha * 255).round()),
          fontSize: 18,
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

    canvas.restore();
  }
}

/// Multiplier display that floats above the score
class MultiplierDisplay extends PositionComponent {
  final int multiplier;
  final double life;
  double _age = 0;

  MultiplierDisplay({
    required super.position,
    required this.multiplier,
    this.life = 1.5,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 20 * dt;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final scale = 0.8 + (1.0 - _age / life) * 0.4;

    // Background glow
    final glowPaint = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha((alpha * 80).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * scale, height: 36 * scale),
        Radius.circular(18 * scale),
      ),
      glowPaint,
    );

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withAlpha((alpha * 230).round());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * scale, height: 36 * scale),
        Radius.circular(18 * scale),
      ),
      bgPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha((alpha * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 80 * scale, height: 36 * scale),
        Radius.circular(18 * scale),
      ),
      borderPaint,
    );

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x$multiplier',
        style: TextStyle(
          color: const Color(0xFFFF4081).withAlpha((alpha * 255).round()),
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}