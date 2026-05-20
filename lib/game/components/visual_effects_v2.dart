import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../ball_bounce_game.dart';

/// Charge ready visual indicator - glowing ring that fills as charge builds
class ChargeReadyIndicator extends PositionComponent with HasGameReference<BallBounceGame> {
  double _chargeLevel = 0;
  double _pulse = 0;
  
  ChargeReadyIndicator() : super(priority: 100);

  @override
  void update(double dt) {
    super.update(dt);
    _chargeLevel = game.chargeShot.chargeLevel;
    _pulse += dt * 8;
  }

  @override
  void render(Canvas canvas) {
    if (_chargeLevel < 0.05 || game.isPaused || game.isGameOver) return;
    
    final ball = game.ball;
    if (ball == null) return;
    
    final cx = ball.position.x - game.size.x / 2;
    final cy = ball.position.y - game.size.y / 2;
    
    // Glow intensity based on charge
    final glowIntensity = (_chargeLevel * 0.6 + 0.2 * (0.5 + 0.5 * sin(_pulse)));
    final glowAlpha = (glowIntensity * 150).round().clamp(0, 200);
    
    // Outer glow ring
    final glowPaint = Paint()
      ..color = Color(0xFFFF9800).withAlpha(glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 25 + _chargeLevel * 10, glowPaint);
    
    // Arc that fills based on charge level
    if (_chargeLevel > 0.3) {
      final arcPaint = Paint()
        ..color = Color(0xFFFFD700).withAlpha((_chargeLevel * 200).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: 20);
      final sweepAngle = _chargeLevel * 2 * pi;
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, arcPaint);
    }
    
    // Full charge flash effect
    if (_chargeLevel >= 1.0) {
      final flashAlpha = (50 + 30 * sin(_pulse * 2)).round().clamp(0, 100);
      final flashPaint = Paint()
        ..color = Color(0xFFFFFFFF).withAlpha(flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), 18, flashPaint);
    }
  }
}

/// Screen-space vignette effect when low health
class DangerVignette extends PositionComponent with HasGameReference<BallBounceGame> {
  double _intensity = 0;
  double _pulse = 0;
  
  DangerVignette() : super(priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 4;
    
    if (game.lives == 1) {
      _intensity = 0.3 + 0.15 * (0.5 + 0.5 * sin(_pulse));
    } else if (game.lives == 2) {
      _intensity = 0.15;
    } else {
      _intensity = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_intensity <= 0) return;
    
    final w = game.size.x;
    final h = game.size.y;
    
    // Red vignette gradient
    final rect = Rect.fromLTWH(-w/2, -h/2, w, h);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Color(0x00000000),
        Color(0x00000000),
        Color(0x33FF0000),
        Color(0x66FF0000),
      ],
      stops: const [0.0, 0.5, 0.8, 1.0],
    );
    
    final rrect = RRect.fromRectAndRadius(rect, Radius.zero);
    canvas.drawRRect(
      rrect,
      Paint()..shader = gradient.createShader(rect),
    );
  }
}

/// Wave completion celebration particles
class WaveCompleteCelebration extends PositionComponent with HasGameReference<BallBounceGame> {
  final int wave;
  final double maxAge = 2.0;
  double _age = 0;
  final List<_CelebrationParticle> _particles = [];
  final Random _rng = Random();

  WaveCompleteCelebration({required this.wave})
      : super(priority: 50);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Spawn 30 celebration particles
    for (int i = 0; i < 30; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 80 + _rng.nextDouble() * 120;
      _particles.add(_CelebrationParticle(
        x: 200,
        y: 200,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 50,
        color: [
          const Color(0xFF00BCD4),
          const Color(0xFFFFD700),
          const Color(0xFFFF5722),
          const Color(0xFF9C27B0),
          const Color(0xFF4CAF50),
        ][_rng.nextInt(5)],
        size: 4 + _rng.nextDouble() * 6,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 120 * dt; // gravity
      p.alpha = (1.0 - _age / maxAge).clamp(0.0, 1.0);
    }
    
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final cx = game.size.x / 2;
    final cy = game.size.y / 2;
    
    for (final p in _particles) {
      final alpha = (p.alpha * 255).round().clamp(0, 255);
      final paint = Paint()..color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(p.x - cx, p.y - cy), p.size * p.alpha, paint);
    }
  }
}

class _CelebrationParticle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double alpha = 1.0;

  _CelebrationParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

/// Trail effect for fast-moving ball
class SpeedTrail extends PositionComponent {
  final Vector2 _pos;
  final Color _color;
  double _life = 0;
  static const double maxLife = 0.3;

  SpeedTrail({required Vector2 position, required Color color})
      : _pos = position.clone(),
        _color = color,
        super(position: position.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = 1.0 - _life / maxLife;
    final alpha = (t * 150).round().clamp(0, 200);
    final radius = 8 * t;
    
    final paint = Paint()
      ..color = _color.withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

/// Particle burst for when ball hits enemy
class ImpactBurst extends Component with HasGameReference<BallBounceGame> {
  final Vector2 position;
  final Color color;
  final double maxAge = 0.4;
  double _age = 0;
  final List<_BurstParticle> _particles = [];
  final Random _rng = Random();

  ImpactBurst({required this.position, required this.color}) {
    for (int i = 0; i < 12; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 100;
      _particles.add(_BurstParticle(
        offset: Vector2.zero(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: 3 + _rng.nextDouble() * 4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    
    for (final p in _particles) {
      p.offset += p.velocity * dt;
      p.velocity *= 0.92;
    }
    
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = 1.0 - _age / maxAge;
    final alpha = (t * 200).round().clamp(0, 255);
    
    for (final p in _particles) {
      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(position.x - game.size.x / 2 + p.offset.x,
               position.y - game.size.y / 2 + p.offset.y),
        p.size * t,
        paint,
      );
    }
  }
}

class _BurstParticle {
  Vector2 offset;
  Vector2 velocity;
  double size;

  _BurstParticle({required this.offset, required this.velocity, required this.size});
}
