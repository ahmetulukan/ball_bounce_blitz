import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Trail segment for enemy projectile
class _ProjectileTrail {
  final Vector2 position;
  final double age;
  _ProjectileTrail(this.position, this.age);
}

class EnemyProjectile extends PositionComponent with CollisionCallbacks {
  static const double projectileSize = 10;
  static const double projectileSpeed = 200;
  double _age = 0;
  static const double maxAge = 4.0;
  Vector2 _velocity = Vector2.zero();
  final List<_ProjectileTrail> _trail = [];
  static const int _maxTrailLength = 8;

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

    // Add trail segment
    _trail.insert(0, _ProjectileTrail(position.clone(), _age));
    if (_trail.length > _maxTrailLength) {
      _trail.removeLast();
    }

    if (_age > maxAge || position.y > 450 || position.x < -10 || position.x > 410) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw trail (from oldest to newest)
    for (int i = _trail.length - 1; i >= 0; i--) {
      final t = _trail[i];
      final ageDiff = _age - t.age;
      final alpha = ((1.0 - ageDiff / 0.4) * 180).clamp(0, 180).toInt();
      final radius = (projectileSize / 2) * (1.0 - ageDiff / 0.4).clamp(0.2, 1.0);

      if (alpha > 0 && radius > 0) {
        // Core trail
        final trailPaint = Paint()
          ..color = Color(0xFFFF5722).withAlpha(alpha)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          (t.position - position).toOffset(),
          radius,
          trailPaint,
        );
      }
    }

    // Outer glow
    final outerGlow = Paint()
      ..color = const Color(0xFFFF8A65).withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, projectileSize / 2 + 4, outerGlow);

    // Core
    final corePaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, projectileSize / 2 - 2, corePaint);

    final paint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, projectileSize / 2, paint);

    // Inner bright spot
    final brightSpot = Paint()
      ..color = Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(-1, -1),
      projectileSize / 4,
      brightSpot,
    );
  }
}