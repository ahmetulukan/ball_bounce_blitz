import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class Barrier extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  int hits;
  static const int maxHits = 3;
  static const double barrierWidth = 80;
  static const double barrierHeight = 12;

  Barrier({required double x, required double y, this.hits = maxHits}) : super(anchor: Anchor.center) {
    position = Vector2(x, y);
    size = Vector2(barrierWidth, barrierHeight);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 15 * dt;
    if (position.y > game.size.y + 30) removeFromParent();
  }

  void takeHit(dynamic scene) {
    hits--;
    if (hits <= 0) {
      for (int i = 0; i < 6; i++) {
        add(BarrierShard(position: position.clone()));
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final hpRatio = hits / maxHits;
    final baseColor = Color.lerp(const Color(0xFF607D8B), const Color(0xFF00BCD4), hpRatio)!;
    final paint = Paint()..color = baseColor;
    final rect = Rect.fromCenter(center: Offset.zero, width: barrierWidth, height: barrierHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < hits; i++) {
      canvas.drawCircle(Offset(-barrierWidth / 2 + 10 + i * 14, 0), 3, dotPaint);
    }
  }
}

class BarrierShard extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  late Vector2 velocity;
  double life = 0.4;
  static final Random _rand = Random();

  BarrierShard({required Vector2 position}) : super(anchor: Anchor.center) {
    this.position = position;
    final angle = (_rand.nextDouble() - 0.5) * 3.14;
    final speed = 80 + _rand.nextDouble() * 120;
    velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
    size = Vector2(6, 6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity.y += 300 * dt;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF00BCD4).withValues(alpha: (life / 0.4).clamp(0.0, 1.0));
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), paint);
  }
}
