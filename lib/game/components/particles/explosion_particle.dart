import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class ExplosionParticle extends PositionComponent {
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double particleRadius;

  ExplosionParticle({
    required Vector2 position,
    required this.velocity,
    required this.color,
    this.life = 0.5,
    this.particleRadius = 4,
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

class ExplosionEffect extends Component {
  final Vector2 position;
  final Color color;
  final int count;
  final double speed;

  ExplosionEffect({
    required this.position,
    this.color = const Color(0xFFFF5722),
    this.count = 12,
    this.speed = 200,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final random = Random();
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + random.nextDouble() * 0.3;
      final vel = Vector2(cos(angle), sin(angle)) * speed * (0.5 + random.nextDouble() * 0.5);
      final particle = ExplosionParticle(
        position: position.clone(),
        velocity: vel,
        color: color,
      );
      add(particle);
    }
  }
}
