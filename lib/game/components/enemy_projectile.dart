import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyProjectile extends PositionComponent with CollisionCallbacks {
  static const double projectileSize = 10;
  static const double projectileSpeed = 200;
  double _age = 0;
  static const double maxAge = 4.0;
  Vector2 _velocity = Vector2.zero();

  EnemyProjectile({required Vector2 position, required double angle})
      : super(
          position: position,
          size: Vector2(projectileSize, projectileSize),
          anchor: Anchor.center,
        ) {
    _velocity = Vector2(sin(angle), cos(angle)) * projectileSpeed;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _age += dt;

    if (_age > maxAge || position.y > 450 || position.x < -10 || position.x > 410) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha(220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, projectileSize / 2, paint);

    final glow = Paint()
      ..color = const Color(0xFFFF8A65).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, projectileSize / 2 + 2, glow);
  }
}