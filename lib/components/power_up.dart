import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'paddle.dart';

enum PowerUpType { speed, shield, multi, shrink, magnet, fireball, explosive }

class PowerUp extends PositionComponent
    with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  final PowerUpType type;
  final dynamic gameScene;
  static const double sizeW = 24;
  static const double sizeH = 24;
  static const double fallSpeed = 100;

  static const List<Color> colors = [
    Color(0xFF00BCD4), // speed - cyan
    Color(0xFF4CAF50), // shield - green
    Color(0xFFFF9800), // multi - orange
    Color(0xFF9C27B0), // shrink - purple
    Color(0xFFE91E63), // magnet - pink
    Color(0xFFFF5722), // fireball - orange-red
    Color(0xFF673AB7), // explosive - deep purple
  ];

  static const List<String> labels = ['⚡', '🛡️', '✖3', '🔻', '🧲', '🔥', '💣'];
  static const List<String> names = ['SPEED', 'SHIELD', 'MULTI', 'SHRINK', 'MAGNET', 'FIREBALL', 'EXPLOSIVE'];

  PowerUp({
    required double x,
    required double y,
    required this.type,
    required this.gameScene,
  }) : super(position: Vector2(x, y), anchor: Anchor.center) {
    add(RectangleHitbox());
    size = Vector2(sizeW, sizeH);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    if (position.y > game.size.y + 30) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Paddle) {
      gameScene?.collectPowerUp(type);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final color = colors[type.index];
    
    // Glow effect
    final glowPaint = Paint()..color = color.withAlpha(50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-2, -2, sizeW + 4, sizeH + 4),
        const Radius.circular(8),
      ),
      glowPaint,
    );

    // Main body
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, sizeW, sizeH), const Radius.circular(6)),
      paint,
    );

    // Shine effect
    final shinePaint = Paint()..color = Colors.white.withAlpha(80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 2, sizeW - 4, sizeH / 2 - 2), const Radius.circular(3)),
      shinePaint,
    );

    // Icon
    final label = labels[type.index];
    final textStyle = TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold);
    final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset((sizeW - tp.width) / 2, (sizeH - tp.height) / 2));
  }
}