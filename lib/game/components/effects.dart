import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

/// Floating score popup that appears when enemies are destroyed
class ScorePopup extends PositionComponent {
  final String text;
  final Color color;
  double _life = 0.8;
  double _vy = -80;

  ScorePopup({
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