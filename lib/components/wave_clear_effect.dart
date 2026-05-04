import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game/game.dart';

class WaveClearEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final List<WaveParticle> particles = [];
  double elapsed = 0;
  final double lifetime;
  final int count;

  WaveClearEffect({
    Vector2? position,
    this.lifetime = 1.5,
    this.count = 30,
    Color color = const Color(0xFF4CAF50),
  }) : super(position: position ?? Vector2(0, 0), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rand = Random();
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 3.14159 * 2;
      final speed = (80 + rand.nextDouble() * 100);
      particles.add(WaveParticle(
        offset: Offset.zero,
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        size: 5 + rand.nextDouble() * 6,
        rotation: rand.nextDouble() * 6.28,
        rotSpeed: (rand.nextDouble() - 0.5) * 8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    for (final p in particles) {
      p.offset = Offset(p.offset.dx + p.velocity.x * dt, p.offset.dy + p.velocity.y * dt);
      p.velocity = p.velocity * 0.94;
      p.rotation += p.rotSpeed * dt;
    }
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - elapsed / lifetime).clamp(0.0, 1.0);
    for (final p in particles) {
      canvas.save();
      canvas.translate(p.offset.dx, p.offset.dy);
      canvas.rotate(p.rotation);
      final paint = Paint()
        ..color = Color.fromARGB((alpha * 255).toInt(), 76, 175, 80)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
      canvas.restore();
    }
  }
}

class WaveParticle {
  Offset offset = Offset.zero;
  Vector2 velocity;
  double size;
  double rotation;
  double rotSpeed;
  WaveParticle({required this.offset, required this.velocity, required this.size, required this.rotation, required this.rotSpeed});
}
