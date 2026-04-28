import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'barrier_shard.dart';

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
    for (int i = 0; i < 8; i++) {
      add(BarrierShard(position: position.clone()));
    }
    scene?.shake();
  }

  @override
  void render(Canvas canvas) {
    final hpRatio = maxHits > 0 ? (hits / maxHits).toDouble() : 0.0;
    final baseColor = Color.lerp(const Color(0xFF607D8B), const Color(0xFF00BCD4), hpRatio)!;
    
    final shadowPaint = Paint()..color = Colors.black.withAlpha(30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barrierWidth / 2 + 2, -barrierHeight / 2 + 2, barrierWidth, barrierHeight),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    final paint = Paint()..color = _flashTimer > 0 ? Colors.white : baseColor;
    final rect = Rect.fromCenter(center: Offset.zero, width: barrierWidth, height: barrierHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

    final shinePaint = Paint()..color = Colors.white.withAlpha(60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-barrierWidth / 2 + 2, -barrierHeight / 2 + 1, barrierWidth - 4, barrierHeight / 2), const Radius.circular(2)),
      shinePaint,
    );

    if (maxHits > 1) {
      final dotPaint = Paint()..color = Colors.white;
      final spacing = (barrierWidth - 16) / (maxHits - 1).toDouble();
      for (int i = 0; i < maxHits; i++) {
        final dotAlpha = i < hits ? 255 : 50;
        dotPaint.color = Colors.white.withAlpha(dotAlpha);
        final dotX = -barrierWidth / 2 + 8 + i * spacing;
        canvas.drawCircle(Offset(dotX, 0), 3, dotPaint);
      }
    }
  }
}