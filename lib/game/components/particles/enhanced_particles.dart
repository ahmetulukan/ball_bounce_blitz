import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Spark particle for quick flashes
class SparkParticle extends PositionComponent {
  Vector2 vel;
  final Color color;
  double _age = 0;
  final double maxAge;
  final double maxSize;

  SparkParticle({
    required Vector2 position,
    required this.vel,
    required this.color,
    double? maxAge,
    this.maxSize = 3,
  }) : maxAge = maxAge ?? 0.4;

  @override
  void update(double dt) {
    super.update(dt);
    position += vel * dt;
    vel *= 0.92; // decelerate
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 255).round().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, maxSize * ((maxAge - _age) / maxAge), paint);
  }
}

/// Confetti particle for achievements
class ConfettiParticle extends PositionComponent {
  Vector2 vel;
  final Color color;
  double _age = 0;
  final double maxAge;
  double _rotation = 0;
  final bool isSquare;

  ConfettiParticle({
    required Vector2 position,
    required this.vel,
    required this.color,
    double? maxAge,
    this.isSquare = true,
  }) : maxAge = maxAge ?? 2.0;

  @override
  void update(double dt) {
    super.update(dt);
    position += vel * dt;
    vel.y += 60 * dt; // gentle gravity
    vel.x *= 0.99;
    _rotation += dt * 5;
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 255).round().clamp(0, 255);
    canvas.save();
    canvas.rotate(_rotation);
    
    final paint = Paint()..color = color.withAlpha(alpha);
    if (isSquare) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 6),
        paint,
      );
    } else {
      canvas.drawCircle(Offset.zero, 4, paint);
    }
    canvas.restore();
  }
}

/// Star particle for special effects
class StarParticle extends PositionComponent {
  final Color color;
  double _age = 0;
  final double maxAge;
  double _rotation = 0;

  StarParticle({
    required Vector2 position,
    required this.color,
    double? maxAge,
  }) : maxAge = maxAge ?? 1.0;

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 2;
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 255).round().clamp(0, 255);
    final scale = 0.5 + ((maxAge - _age) / maxAge) * 0.5;
    canvas.save();
    canvas.rotate(_rotation);
    canvas.scale(scale);
    
    final paint = Paint()..color = color.withAlpha(alpha);
    _drawStar(canvas, Offset.zero, 6, paint);
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final ang = (i * 72 - 90) * pi / 180;
      final x = center.dx + cos(ang) * radius;
      final y = center.dy + sin(ang) * radius;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final ix = center.dx + cos(innerAngle) * radius * 0.4;
      final iy = center.dy + sin(innerAngle) * radius * 0.4;
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Ring expand effect
class RingEffect extends PositionComponent {
  final Color color;
  double _age = 0;
  final double maxAge;
  double _radius = 0;

  RingEffect({
    required Vector2 position,
    required this.color,
    double? maxAge,
  }) : maxAge = maxAge ?? 0.5;

  @override
  void update(double dt) {
    super.update(dt);
    _radius += 150 * dt;
    _age += dt;
    if (_age >= maxAge) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((maxAge - _age) / maxAge * 180).round().clamp(0, 180);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * ((maxAge - _age) / maxAge);
    canvas.drawCircle(Offset.zero, _radius, paint);
  }
}

/// Power-up collection burst - spawns multiple particle types
class PowerUpBurst extends Component {
  final Vector2 pos;
  final Color color;

  PowerUpBurst({required this.pos, required this.color});

  @override
  Future<void> onLoad() async {
    final random = Random();
    
    // Spawn sparks
    for (int i = 0; i < 12; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final spd = 150 + random.nextDouble() * 100;
      final spark = SparkParticle(
        position: pos.clone(),
        vel: Vector2(cos(angle) * spd, sin(angle) * spd),
        color: color,
        maxAge: 0.3 + random.nextDouble() * 0.3,
        maxSize: 2 + random.nextDouble() * 3,
      );
      add(spark);
    }
    
    // Spawn confetti
    final confettiColors = [
      color,
      const Color(0xFFFFD700),
      const Color(0xFFFFFFFF),
    ];
    for (int i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final spd = 80 + random.nextDouble() * 60;
      final confetti = ConfettiParticle(
        position: pos.clone(),
        vel: Vector2(cos(angle) * spd, sin(angle) * spd - 50),
        color: confettiColors[random.nextInt(confettiColors.length)],
        maxAge: 1.0 + random.nextDouble() * 0.5,
      );
      add(confetti);
    }
    
    // Spawn ring effect
    add(RingEffect(position: pos.clone(), color: color));
  }
}

/// Achievement celebration burst with confetti
class AchievementBurst extends Component {
  final Vector2 pos;

  AchievementBurst({required this.pos});

  @override
  Future<void> onLoad() async {
    final random = Random();
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
    ];
    
    // Confetti explosion
    for (int i = 0; i < 25; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final spd = 100 + random.nextDouble() * 150;
      final confetti = ConfettiParticle(
        position: pos.clone() + Vector2(0, -20),
        vel: Vector2(cos(angle) * spd, sin(angle) * spd - 100),
        color: colors[random.nextInt(colors.length)],
        maxAge: 1.5 + random.nextDouble() * 1.0,
      );
      add(confetti);
    }
    
    // Stars
    for (int i = 0; i < 5; i++) {
      final offset = Vector2(
        (random.nextDouble() - 0.5) * 60,
        (random.nextDouble() - 0.5) * 60,
      );
      final star = StarParticle(
        position: pos.clone() + offset,
        color: colors[random.nextInt(colors.length)],
        maxAge: 0.8 + random.nextDouble() * 0.5,
      );
      add(star);
    }
  }
}

/// Gravity well effect for special power-ups
class GravityWell extends PositionComponent {
  final double maxAge;
  double _age = 0;
  final double strength;

  GravityWell({
    required Vector2 position,
    double? maxAge,
    this.strength = 200,
  }) : maxAge = maxAge ?? 3.0;

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
    double? maxAge,
  }) : maxAge = maxAge ?? 5.0;

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