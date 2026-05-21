import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Chain reaction effect that triggers when a splitting enemy dies near others
class ChainReactionEffect extends PositionComponent {
  final Color baseColor;
  final double maxAge;
  double _age = 0;
  final int particleCount;

  ChainReactionEffect({
    required Vector2 position,
    this.baseColor = const Color(0xFFFF5722),
    this.maxAge = 0.6,
    this.particleCount = 12,
  }) : super(position: position, anchor: Anchor.center);

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
    final alpha = ((1.0 - t) * 255).round().clamp(0, 255);

    // Draw expanding ring
    final ringRadius = 20 + t * 60;
    final ringPaint = Paint()
      ..color = baseColor.withAlpha((alpha * 0.7).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = (3 * (1 - t)).round().toDouble();
    canvas.drawCircle(Offset.zero, ringRadius, ringPaint);

    // Inner flash
    if (t < 0.2) {
      final flashAlpha = ((1 - t / 0.2) * 150).round().clamp(0, 255);
      final flashPaint = Paint()
        ..color = baseColor.withAlpha(flashAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, ringRadius * 0.5, flashPaint);
    }
  }
}

/// Debris particle for destruction effects
class DebrisParticle extends PositionComponent {
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  double _rotation = 0;
  final double rotationSpeed;

  DebrisParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.size = 6,
    this.life = 0.6,
    this.rotationSpeed = 0,
  })  : maxLife = life,
        super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity.y += 200 * dt; // gravity
    velocity *= 0.99;
    life -= dt;
    _rotation += rotationSpeed * dt;
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (life <= 0) return;
    final alpha = (life / maxLife * 255).round().clamp(0, 255);
    final currentSize = size * (life / maxLife).clamp(0.3, 1.0);

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(_rotation);

    final paint = Paint()..color = color.withAlpha(alpha);
    // Draw rectangular debris
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: currentSize, height: currentSize * 0.7),
      paint,
    );

    canvas.restore();
  }
}

/// Spawn debris burst at a position
void spawnDebrisBurst(Vector2 position, Color color, int count, double speed, Component parent) {
  final random = Random();
  for (int i = 0; i < count; i++) {
    final angle = random.nextDouble() * 2 * pi;
    final spd = speed * (0.5 + random.nextDouble() * 0.5);
    final debris = DebrisParticle(
      position: position.clone(),
      velocity: Vector2(cos(angle) * spd, sin(angle) * spd - 50),
      color: color,
      size: 4 + random.nextDouble() * 4,
      rotationSpeed: (random.nextDouble() - 0.5) * 10,
    );
    parent.add(debris);
  }
}

/// Smoke puff effect for heavy enemy destruction
class SmokePuff extends PositionComponent {
  double _age = 0;
  final double maxAge = 0.8;
  final Color baseColor;

  SmokePuff({
    required Vector2 position,
    this.baseColor = const Color(0xFF607D8B),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 30 * dt; // rise
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 120).round().clamp(0, 255);
    final radius = 15 + t * 25;

    final paint = Paint()
      ..color = baseColor.withAlpha(alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

/// Lightning arc effect for chain lightning power-up
class LightningArc extends PositionComponent {
  final Vector2 start;
  final Vector2 end;
  double _age = 0;
  final double maxAge = 0.2;
  final int segments;
  final List<Vector2> _points = [];

  LightningArc({
    required this.start,
    required this.end,
    this.segments = 6,
  }) : super(anchor: Anchor.center) {
    _generatePoints();
  }

  void _generatePoints() {
    final random = Random();
    _points.add(start.clone());
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final base = start + (end - start) * t;
      final offset = (random.nextDouble() - 0.5) * 30;
      final dir = (end - start).normalized();
      final perp = Vector2(-dir.y, dir.x);
      _points.add(base + perp * offset);
    }
    _points.add(end.clone());
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
    final alpha = ((1 - _age / maxAge) * 255).round().clamp(0, 255);
    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF87CEEB).withAlpha((alpha * 0.5).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()..moveTo(_points[0].x, _points[0].y);
    for (int i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].x, _points[i].y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }
}

/// Critical hit text popup for bonus damage
class CriticalHitText extends PositionComponent {
  final String text;
  double _life = 0.8;
  double _vy = -100;
  double _scale = 1.0;
  final Color color;

  CriticalHitText({
    required Vector2 position,
    this.text = 'CRITICAL!',
    this.color = const Color(0xFFFF0000),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy += 80 * dt;
    _scale = 1.0 + (_life / 0.8) * 0.5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final alpha = (_life / 0.8 * 255).round().clamp(0, 255);

    final shadowPaint = Paint()..color = Colors.black.withAlpha((alpha * 0.5).round());
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha(alpha),
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
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}