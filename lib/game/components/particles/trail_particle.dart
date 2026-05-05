import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class TrailParticle extends PositionComponent {
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double particleRadius;

  TrailParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.life = 0.25,
    this.particleRadius = 3,
  }) : maxLife = life, super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    life -= dt;
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / maxLife * 255).toInt().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, particleRadius * (life / maxLife), paint);
  }
}