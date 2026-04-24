import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import '../../services/audio_manager.dart';

class BossEnemy extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  double speed;
  int hits;
  int maxHits;
  final dynamic gameScene;
  static const double width = 80;
  static const double height = 80;

  BossEnemy({required double x, required double y, required this.speed, required this.gameScene, int wave = 1})
      : super(anchor: Anchor.center) {
    position = Vector2(x, y);
    hits = 3 + wave;
    maxHits = hits;
    size = Vector2(width, height);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;

    // Gentle horizontal oscillation
    position.x += (position.x > 60 && position.x < (game.size.x - 60))
        ? (position.x < game.size.x / 2 ? 1.0 : -1.0) * 20 * dt
        : 0;

    if (position.y > game.size.y + 100) removeFromParent();
  }

  void takeHit(dynamic scene) {
    hits--;
    scene?.shake();

    if (hits <= 0) {
      AudioManager.playScore();
      scene?.onScore(200);
      scene?.onEnemyDestroyed();
      scene?.onBossDefeated();
      removeFromParent();
    } else {
      scene?.onPartialHit();
    }
  }

  @override
  void render(Canvas canvas) {
    // Body
    final bodyPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(-width / 2, -height / 2, width, height), bodyPaint);

    // Border glow
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(-width / 2, -height / 2, width, height), borderPaint);

    // Inner pattern
    final innerPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset.zero, 15, innerPaint);

    // HP bar
    final hpBg = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(Rect.fromLTWH(-width / 2, -height / 2 - 12, width, 6), hpBg);
    final hpFill = Paint()..color = Color.lerp(const Color(0xFFE91E63), const Color(0xFFFFEB3B), hits / maxHits)!;
    canvas.drawRect(Rect.fromLTWH(-width / 2, -height / 2 - 12, width * (hits / maxHits), 6), hpFill);

    // Crown icon on boss
    final crownPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Draw a small crown
    canvas.drawLine(Offset(-10, 5), Offset(-15, -5), crownPaint);
    canvas.drawLine(Offset(-15, -5), Offset(-8, -10), crownPaint);
    canvas.drawLine(Offset(-8, -10), Offset(0, -3), crownPaint);
    canvas.drawLine(Offset(0, -3), Offset(8, -10), crownPaint);
    canvas.drawLine(Offset(8, -10), Offset(15, -5), crownPaint);
    canvas.drawLine(Offset(15, -5), Offset(10, 5), crownPaint);
    canvas.drawLine(Offset(-10, 5), Offset(10, 5), crownPaint);
  }
}
