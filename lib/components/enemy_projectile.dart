import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'paddle.dart';

/// Enemy projectile shot by shooter type enemies
class EnemyProjectile extends PositionComponent with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  static const double speed = 150;
  static const double _size = 8;
  bool _hit = false;
  final dynamic _gameScene;

  EnemyProjectile({required double x, required double y, required dynamic gameScene}) 
      : _gameScene = gameScene,
        super(position: Vector2(x, y), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    size = Vector2(_size * 2, _size * 2);
    add(CircleHitbox(radius: _size / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hit) return;
    position.y += speed * dt;
    if (position.y > game.size.y + 20) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_hit) return;
    if (other is Paddle) {
      _hit = true;
      (_gameScene as dynamic)?.onProjectileHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Danger glow
    final glowPaint = Paint()..color = const Color(0x60F44336);
    canvas.drawCircle(Offset(_size / 2, _size / 2), _size / 2 + 3, glowPaint);

    // Main projectile
    final paint = Paint()..color = const Color(0xFFF44336);
    canvas.drawCircle(Offset(_size / 2, _size / 2), _size / 2, paint);

    // Core
    final corePaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(_size / 2, _size / 2), _size / 4, corePaint);
  }
}