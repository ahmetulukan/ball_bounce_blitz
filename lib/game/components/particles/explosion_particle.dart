import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class ExplosionParticle extends PositionComponent {
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double particleRadius;
  final bool isSpark;
  final double rotationSpeed;

  double _rotation = 0;

  ExplosionParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.life = 0.5,
    this.particleRadius = 4,
    this.isSpark = false,
    this.rotationSpeed = 0,
  }) : maxLife = life, super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity *= 0.98; // drag
    life -= dt;
    _rotation += rotationSpeed * dt;
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / maxLife * 255).toInt().clamp(0, 255);
    final radius = particleRadius * (life / maxLife);

    if (isSpark) {
      // Diamond/spark shape
      canvas.save();
      canvas.rotate(_rotation);
      final path = Path()
        ..moveTo(0, -radius)
        ..lineTo(radius * 0.4, 0)
        ..lineTo(0, radius)
        ..lineTo(-radius * 0.4, 0)
        ..close();
      
      final paint = Paint()..color = color.withAlpha(alpha);
      canvas.drawPath(path, paint);
      
      // Glow
      final glowPaint = Paint()
        ..color = color.withAlpha((alpha * 0.5).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glowPaint);
      canvas.restore();
    } else {
      // Circle
      final paint = Paint()..color = color.withAlpha(alpha);
      canvas.drawCircle(Offset.zero, radius, paint);
      
      // Glow for fireball
      if (particleRadius > 3) {
        final glowPaint = Paint()
          ..color = color.withAlpha((alpha * 0.4).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset.zero, radius * 1.5, glowPaint);
      }
    }
  }
}

class ExplosionEffect extends PositionComponent {
  final Color color;
  final int count;
  final double speed;
  final int sparkCount;

  ExplosionEffect({
    required super.position,
    this.color = const Color(0xFFFF5722),
    this.count = 12,
    this.speed = 200,
    this.sparkCount = 6,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = Random();

    // Regular particles
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + random.nextDouble() * 0.3;
      final vel = Vector2(cos(angle), sin(angle)) * speed * (0.5 + random.nextDouble() * 0.5);
      final particle = ExplosionParticle(
        position: position.clone(),
        velocity: vel,
        color: color,
        particleRadius: 3 + random.nextDouble() * 3,
      );
      add(particle);
    }

    // Sparks
    for (int i = 0; i < sparkCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final vel = Vector2(cos(angle), sin(angle)) * speed * (0.8 + random.nextDouble() * 0.6);
      final spark = ExplosionParticle(
        position: position.clone(),
        velocity: vel,
        color: const Color(0xFFFFEB3B),
        particleRadius: 2,
        isSpark: true,
        rotationSpeed: random.nextDouble() * 10,
        life: 0.4,
      );
      add(spark);
    }
  }
}

/// Ring expansion effect (like shockwave)
class RingEffect extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double life;
  double _age = 0;

  RingEffect({
    required super.position,
    this.color = const Color(0xFF00BCD4),
    this.maxRadius = 80,
    this.life = 0.5,
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
    final alpha = (1.0 - t);
    final radius = maxRadius * t;

    // Outer ring
    final outerPaint = Paint()
      ..color = color.withAlpha((alpha * 150).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1.0 - t);
    canvas.drawCircle(Offset.zero, radius, outerPaint);

    // Inner glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 60).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * 0.8, glowPaint);
  }
}

/// Star burst for achievements
class StarBurst extends PositionComponent {
  final double life;
  final Color color;
  double _age = 0;

  StarBurst({
    required super.position,
    this.life = 0.8,
    this.color = const Color(0xFFFFD700),
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
    final alpha = (1.0 - t);
    final scale = 1.0 + t * 2;

    // Draw 8-pointed star
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = (i * pi / 8) - pi / 2;
      final r = (i.isEven) ? 15 * scale : 6 * scale;
      final x = cos(angle) * r;
      final y = sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()..color = color.withAlpha((alpha * 255).round());
    canvas.drawPath(path, paint);

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 100).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(path, glowPaint);
  }
}