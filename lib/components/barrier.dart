import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class Barrier extends PositionComponent with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  int hits;
  int maxHits;
  static const double barrierWidth = 80;
  static const double barrierHeight = 12;
  bool _isDestroying = false;
  double _flashTimer = 0;

  Barrier({required double x, required double y, this.hits = 3}) : maxHits = hits, super(anchor: Anchor.center) {
    position = Vector2(x, y);
    size = Vector2(barrierWidth, barrierHeight);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroying) return;
    if (_flashTimer > 0) _flashTimer -= dt;
    position.y += 15 * dt;
    if (position.y > game.size.y + 30) removeFromParent();
  }

  void takeHit(dynamic scene) {
    if (_isDestroying) return;
    hits--;
    _flashTimer = 0.08;
    
    if (hits <= 0) {
      _isDestroying = true;
      _playDestroyEffect(scene);
      removeFromParent();
    } else {
      scene?.onPartialHit();
    }
  }

  void _playDestroyEffect(dynamic scene) {
    // Spawn shatter particles
    for (int i = 0; i < 8; i++) {
      add(BarrierShard(position: position.clone()));
    }
    scene?.shake();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    // Ball collision is handled by Ball.onCollision
  }

  @override
  void render(Canvas canvas) {
    final hpRatio = maxHits > 0 ? hits / maxHits : 0;
    final baseColor = Color.lerp(const Color(0xFF607D8B), const Color(0xFF00BCD4), hpRatio)!;
    
    // Shadow
    final shadowPaint = Paint()..color = Colors.black.withAlpha(30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barrierWidth / 2 + 2, -barrierHeight / 2 + 2, barrierWidth, barrierHeight),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Main body with flash
    final paint = Paint()..color = _flashTimer > 0 ? Colors.white : baseColor;
    final rect = Rect.fromCenter(center: Offset.zero, width: barrierWidth, height: barrierHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

    // Shine effect
    final shinePaint = Paint()..color = Colors.white.withAlpha(60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-barrierWidth / 2 + 2, -barrierHeight / 2 + 1, barrierWidth - 4, barrierHeight / 2), const Radius.circular(2)),
      shinePaint,
    );

    // HP indicator dots
    final dotPaint = Paint()..color = Colors.white;
    for (int i = 0; i < maxHits; i++) {
      final dotAlpha = i < hits ? 255 : 50;
      dotPaint.color = Colors.white.withAlpha(dotAlpha);
      final dotX = -barrierWidth / 2 + 8 + i * (barrierWidth - 16) / (maxHits - 1).clamp(1, maxHits - 1);
      canvas.drawCircle(Offset(dotX, 0), 3, dotPaint);
    }
  }
}

class BarrierShard extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  late Vector2 velocity;
  double life = 0.5;
  static final Random _rand = Random();
  final double _angle;
  final double _speed;

  BarrierShard({required Vector2 position}) : _angle = (_rand.nextDouble() - 0.5) * 3.14, _speed = 80 + _rand.nextDouble() * 120, super(anchor: Anchor.center) {
    this.position = position;
    velocity = Vector2(_rand.nextDouble() * _speed * (_rand.nextBool() ? 1 : -1), -50 - _rand.nextDouble() * 80);
    size = Vector2(6, 6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity.y += 250 * dt; // gravity
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 0.5).clamp(0.0, 1.0);
    final paint = Paint()..color = const Color(0xFF00BCD4).withAlpha((alpha * 255).toInt());
    canvas.save();
    canvas.rotate(_angle);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), paint);
    canvas.restore();
  }
}