import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'ball.dart';

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
    // Use full game canvas size instead of hardcoded 400x400
    final gameSize = gameRef.size;
    canvas.drawRect(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y), paint);
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
  final double _orbitRadius = 18;

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

/// Screen flash on big hits
class ScreenFlash extends Component {
  final double duration;
  final Color color;
  double _elapsed = 0;

  ScreenFlash({
    this.duration = 0.15,
    this.color = const Color(0xFFFFFFFF),
  });

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - _elapsed / duration) * 0.35).round().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 600), paint);
  }
}

/// Shockwave ring expanding from explosion
class ShockwaveRing extends PositionComponent {
  double _radius = 0;
  final double maxRadius;
  final double speed;
  final Color color;

  ShockwaveRing({
    required super.position,
    this.maxRadius = 120,
    this.speed = 300,
    this.color = const Color(0xFFFFD700),
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _radius += speed * dt;
    if (_radius >= maxRadius) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final life = 1 - (_radius / maxRadius);
    final alpha = (life * 200).round().clamp(0, 255);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (3 * life).clamp(0.5, 3);
    canvas.drawCircle(Offset.zero, _radius, paint);
  }
}

/// Hit marker burst effect
class HitMarkerBurst extends PositionComponent {
  double _life = 0.3;
  final Color color;
  final int rays;

  HitMarkerBurst({
    required super.position,
    this.color = const Color(0xFFFFFFFF),
    this.rays = 8,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.3 * 255).round().clamp(0, 255);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * pi;
      final len = 10 + (1 - _life / 0.3) * 15;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * len, sin(angle) * len),
        paint,
      );
    }
  }
}

/// Critical hit text popup
class CriticalHitText extends PositionComponent {
  double _life = 0.6;

  CriticalHitText({required Vector2 position}) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.6 * 255).round().clamp(0, 255);
    final scale = 0.8 + (1 - _life / 0.6) * 0.5;
    
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha(alpha ~/ 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, 20 * scale, glowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CRITICAL!',
        style: TextStyle(
          color: const Color(0xFF00E5FF).withAlpha(alpha),
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0xFF000000), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Ghost trail for fireball/laser ball
class GhostTrail extends PositionComponent {
  final Color color;
  double _life = 0.2;

  GhostTrail({required Vector2 position, required this.color}) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.2 * 100).round().clamp(0, 100);
    final radius = _life / 0.2 * 8;

    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

/// Magnet field visual effect
class MagnetField extends PositionComponent {
  final double maxAge;
  double _age = 0;
  double _phase = 0;

  MagnetField({required Vector2 position, required this.maxAge}) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _phase += dt * 8;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final lifeRatio = 1 - (_age / maxAge);
    final alpha = (lifeRatio * 150).round().clamp(0, 150);
    
    // Pulsing ring
    final ringRadius = 80 + sin(_phase) * 10;
    final ringPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset.zero, ringRadius * lifeRatio, ringPaint);

    // Attraction lines
    for (int i = 0; i < 6; i++) {
      final angle = (_phase * 0.5) + (i * pi / 3);
      final lineLength = 40 * lifeRatio;
      final linePaint = Paint()
        ..color = const Color(0xFFE91E63).withAlpha((alpha * 0.7).round())
        ..strokeWidth = 1.5;
      
      final startX = cos(angle) * ringRadius * 0.5 * lifeRatio;
      final startY = sin(angle) * ringRadius * 0.5 * lifeRatio;
      final endX = cos(angle) * (ringRadius + lineLength) * lifeRatio;
      final endY = sin(angle) * (ringRadius + lineLength) * lifeRatio;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }
  }
}

/// Laser beam component
class LaserBeam extends PositionComponent with HasGameRef<BallBounceGame> {
  double _life = 0.15;

  LaserBeam({required Vector2 position}) : super(position: position, anchor: Anchor.topCenter);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.15 * 255).round().clamp(0, 255);
    final double width = 400; // screen width

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF00).withAlpha(alpha ~/ 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRect(
      Rect.fromLTWH(-width / 2, 0, width, 400),
      glowPaint,
    );

    // Core beam
    final beamPaint = Paint()..color = const Color(0xFF00FF00).withAlpha(alpha);
    canvas.drawRect(Rect.fromLTWH(-width / 2, -2, width, 4), beamPaint);
  }
}

/// Combo multiplier popup (x2, x3, etc.)
class ComboMultiplierPopup extends PositionComponent {
  final int combo;
  double _life = 1.0;
  double _vy = -50;

  ComboMultiplierPopup({
    required super.position,
    required this.combo,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy *= 0.97;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 1.0 * 255).round().clamp(0, 255);
    final scale = 0.6 + (1 - _life / 1.0) * 0.6;
    final color = _getComboColor();

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, 25 * scale, glowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x$combo',
        style: TextStyle(
          color: color.withAlpha(alpha),
          fontSize: 20 * scale,
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

  Color _getComboColor() {
    if (combo >= 15) return const Color(0xFFFF1493); // Deep pink
    if (combo >= 10) return const Color(0xFFFF5722); // Orange
    if (combo >= 5) return const Color(0xFFFFEB3B);  // Yellow
    return const Color(0xFF4CAF50);                  // Green
  }
}

/// Full-screen shockwave ring effect
class ShockwaveEffect extends Component {
  final Vector2 position;
  final Color color;
  double _life = 0.8;
  double _radius = 0;

  ShockwaveEffect({
    required this.position,
    required this.color,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _radius += 400 * dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.8 * 180).round().clamp(0, 255);
    final width = (3 * _life / 0.8).clamp(0.5, 3.0);

    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawCircle(
      Offset(position.x, position.y),
      _radius,
      paint,
    );

    // Second inner ring
    if (_radius > 30) {
      final innerPaint = Paint()
        ..color = color.withAlpha((alpha * 0.6).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.6;
      canvas.drawCircle(
        Offset(position.x, position.y),
        _radius * 0.6,
        innerPaint,
      );
    }
  }
}

/// Streak fire effect trailing the ball
class StreakFire extends PositionComponent {
  final Color baseColor;
  double _life = 0.4;
  final double particleSize;

  StreakFire({
    required Vector2 position,
    required this.baseColor,
    this.particleSize = 12,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.4 * 120).round().clamp(0, 120);
    final radius = particleSize * (_life / 0.4);

    final paint = Paint()..color = baseColor.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, radius, paint);

    // Bright core
    final corePaint = Paint()..color = const Color(0xFFFFFFFF).withAlpha((alpha * 0.6).round());
    canvas.drawCircle(Offset.zero, radius * 0.4, corePaint);
  }
}
/// Energy shield effect that orbits around the ball
class EnergyShieldEffect extends PositionComponent with HasGameRef<BallBounceGame> {
  double _age = 0;
  final double maxAge = 4.0;
  double _rotation = 0;
  late Vector2 ballPosition;

  EnergyShieldEffect();

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 6;
    
    // Follow the ball
    final balls = gameRef.children.whereType<Ball>().toList();
    if (balls.isNotEmpty) {
      position = balls.first.position.clone();
    }
    
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / maxAge) * 180;
    
    for (int i = 0; i < 4; i++) {
      final angle = _rotation + (i * pi / 2);
      final px = cos(angle) * 18;
      final py = sin(angle) * 18;
      
      // Glow
      final glowPaint = Paint()
        ..color = const Color(0xFF00E5FF).withAlpha((alpha * 0.5).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(px, py), 8, glowPaint);
      
      // Core
      final corePaint = Paint()..color = const Color(0xFF00E5FF).withAlpha(alpha.round());
      canvas.drawCircle(Offset(px, py), 5, corePaint);
    }
    
    // Shield ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((alpha * 0.6).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, 16, ringPaint);
  }
}

/// Freeze time visual effect overlay
class FreezeTimeEffect extends PositionComponent with HasGameRef<BallBounceGame> {
  double _age = 0;
  final double maxAge = 3.0;
  double _pulse = 0;

  FreezeTimeEffect();

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _pulse += dt * 4;
    
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final lifeRatio = 1 - (_age / maxAge);
    final alpha = lifeRatio * 40;
    final borderAlpha = (sin(_pulse) * 10 + 15).round().clamp(0, 25);
    
    // Screen tint
    final tintPaint = Paint()
      ..color = const Color(0xFF81D4FA).withAlpha(alpha.round());
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 400), tintPaint);
    
    // Border pulse
    final borderPaint = Paint()
      ..color = const Color(0xFF81D4FA).withAlpha(borderAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRect(Rect.fromLTWH(2, 2, 396, 396), borderPaint);
    
    // Freeze particles
    if (gameRef.size.x > 0) {
      final random = Random();
      for (int i = 0; i < 8; i++) {
        final px = random.nextDouble() * 400;
        final py = random.nextDouble() * 400;
        final snowAlpha = (alpha * (0.3 + random.nextDouble() * 0.4)).round().clamp(0, 255);
        final snowPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withAlpha(snowAlpha);
        canvas.drawCircle(Offset(px, py), 2 + random.nextDouble() * 2, snowPaint);
      }
    }
  }
}

/// Score bonus popup for wave clear
class WaveBonusText extends PositionComponent {
  final int wave;
  double _life = 1.2;
  double _vy = -60;

  WaveBonusText({required Vector2 position, required this.wave}) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy *= 0.97;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 1.2 * 255).round().clamp(0, 255);
    final scale = 0.6 + (1 - _life / 1.2) * 0.5;
    
    final bonus = 50 * wave;
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$bonus BONUS',
        style: TextStyle(
          color: const Color(0xFF4CAF50).withAlpha(alpha),
          fontSize: 18 * scale,
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
/// Screen flash overlay for events
class ScreenFlashOverlay extends PositionComponent with HasGameRef<BallBounceGame> {
  final Color color;
  final double maxAge;
  double _age = 0;

  ScreenFlashOverlay({required this.color, this.maxAge = 0.15});

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1 - _age / maxAge) * 0.25).round().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawRect(Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y), paint);
  }
}

/// Enhanced screen border effects for game states
class BorderGlowEffect extends PositionComponent with HasGameRef<BallBounceGame> {
  final Color color;
  final double maxAge;
  final double thickness;
  double _age = 0;

  BorderGlowEffect({
    required this.color,
    this.maxAge = 0.5,
    this.thickness = 12,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final lifeRatio = (1 - _age / maxAge).clamp(0.0, 1.0);
    final alpha = (lifeRatio * 180).round().clamp(0, 255);
    
    final w = gameRef.size.x;
    final h = gameRef.size.y;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * lifeRatio
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromLTWH(thickness / 2, thickness / 2, w - thickness, h - thickness),
      glowPaint,
    );

    // Inner border
    final borderPaint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * lifeRatio;
    canvas.drawRect(
      Rect.fromLTWH(thickness / 2, thickness / 2, w - thickness, h - thickness),
      borderPaint,
    );
  }
}

/// Chain reaction explosion visual
class ChainExplosionRing extends PositionComponent {
  final Color color;
  final double maxAge;
  double _age = 0;
  double _radius = 0;

  ChainExplosionRing({
    required Vector2 position,
    required this.color,
    this.maxAge = 0.6,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _radius += 200 * dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 200).round().clamp(0, 255);
    final width = (4 * (1 - t)).clamp(0.5, 4.0);

    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    canvas.drawCircle(Offset.zero, _radius, paint);

    // Lightning arc effect
    if (t < 0.3) {
      final arcAlpha = ((1 - t / 0.3) * 255).round().clamp(0, 255);
      final arcPaint = Paint()
        ..color = const Color(0xFF00FFFF).withAlpha(arcAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      // Draw zigzag lightning
      final path = Path();
      final segments = 4;
      for (int i = 0; i <= segments; i++) {
        final px = cos(i * 2 * pi / segments) * _radius * 0.8;
        final py = sin(i * 2 * pi / segments) * _radius * 0.8;
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          // Add slight randomness for lightning feel
          final jitterX = (i % 2 == 0) ? 5.0 : -5.0;
          path.lineTo(px + jitterX, py);
        }
      }
      canvas.drawPath(path, arcPaint);
    }
  }
}

/// Score floating text with animation
class AnimatedScoreText extends PositionComponent {
  final int score;
  final double maxAge;
  double _age = 0;
  double _vy = -40;

  AnimatedScoreText({
    required Vector2 position,
    required this.score,
    this.maxAge = 1.0,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.96;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 255).round().clamp(0, 255);
    final scale = 0.6 + (1 - t) * 0.5;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$score',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
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
