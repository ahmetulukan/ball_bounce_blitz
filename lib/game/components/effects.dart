import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

/// Floating score popup that appears when enemies are destroyed
class FloatingScorePopup extends PositionComponent {
  final String text;
  final Color color;
  double _life = 0.8;
  double _vy = -80;

  FloatingScorePopup({
    required super.position,
    required this.text,
    this.color = const Color(0xFFFFD700),
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy *= 0.95; // slow down
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.8 * 255).round().clamp(0, 255);
    final scale = 0.8 + (_life / 0.8) * 0.4;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha(alpha),
          fontSize: 16 * scale,
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
  }
}

/// Combo milestone flash effect
class ComboFlash extends Component {
  final int comboLevel;
  double _life = 0.5;
  late BallBounceGame gameRef;

  ComboFlash({required this.comboLevel});

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
    final alpha = (_life / 0.5 * 80).round().clamp(0, 80);
    final paint = Paint()
      ..color = Color(0xFFFF9800).withAlpha(alpha)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
  }
}

/// Wave clear celebration text
class WaveClearText extends PositionComponent {
  double _life = 1.5;
  double _scale = 0.5;

  WaveClearText({required super.position}) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _scale = 0.5 + (1.0 - _life / 1.5) * 0.8;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 1.5 * 255).round().clamp(0, 255);
    
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha ~/ 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 50 * _scale, glowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'WAVE CLEAR!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 24 * _scale,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          shadows: const [
            Shadow(color: Color(0xFF000000), blurRadius: 8),
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

/// Power-up active indicator on ball
class BallPowerUpIndicator extends PositionComponent {
  final Color color;
  final String icon;
  double _phase = 0;
  double _orbitRadius = 18;

  BallPowerUpIndicator({
    required this.color,
    required this.icon,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 4;
  }

  @override
  void render(Canvas canvas) {
    final x = _orbitRadius * 0.7;
    final y = _orbitRadius * 0.7;
    
    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(x, y), 10, glowPaint);

    // Icon circle
    final bgPaint = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), 8, bgPaint);

    // Icon text
    final textPainter = TextPainter(
      text: TextSpan(
        text: icon,
        style: const TextStyle(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }
}

/// Slow motion visual overlay
class SlowMoOverlay extends PositionComponent {
  double _life = 5.0;
  double _pulse = 0;

  SlowMoOverlay();

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _pulse += dt * 3;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 5.0 * 30).round().clamp(0, 30);
    final paint = Paint()
      ..color = const Color(0xFF673AB7).withAlpha(alpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), paint);
    
    // Pulsing border
    final borderAlpha = (sin(_pulse) * 15 + 20).round().clamp(0, 35);
    final borderPaint = Paint()
      ..color = const Color(0xFF673AB7).withAlpha(borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(Rect.fromLTWH(2, 2, 396, 396), borderPaint);
  }
}
/// Gravity well effect for special power-ups
class GravityWell extends PositionComponent {
  final double maxAge;
  double _age = 0;
  final double strength;

  GravityWell({
    required Vector2 position,
    this.maxAge = 3.0,
    this.strength = 200,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - _age / maxAge) * 100).round().clamp(0, 100);
    final radius = 30 + sin(_age * 4) * 10;
    
    final paint = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset.zero, radius, paint);
    
    final innerPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha(alpha ~/ 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);
  }
}

/// Magnet field visual effect
class MagnetField extends PositionComponent {
  double _age = 0;
  final double maxAge;

  MagnetField({
    required Vector2 position,
    this.maxAge = 5.0,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - _age / maxAge) * 60).round().clamp(0, 60);
    final radius = 20 + sin(_age * 5) * 5;
    
    final paint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
