import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

enum PowerUpType { speed, shield, multi, shrink }

class PowerUp extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final PowerUpType type;
  static const double sizeW = 24;
  static const double sizeH = 24;
  static const double fallSpeed = 100;

  static const List<Color> colors = [
    Color(0xFF00BCD4), // speed - cyan
    Color(0xFF4CAF50), // shield - green
    Color(0xFFFF9800), // multi - orange
    Color(0xFF9C27B0), // shrink - purple
  ];

  static const List<String> labels = ['⚡', '🛡️', '✖3', '🔻'];

  PowerUp({required double x, required double y, required this.type}) : super(position: Vector2(x, y), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    if (position.y > gameRef.size.y + 30) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final color = colors[type.index];
    final paint = Paint()..color = color;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, sizeW, sizeH), const Radius.circular(6)), paint);

    final label = labels[type.index];
    final textPainter = TextPainter(text: TextSpan(text: label, style: const TextStyle(fontSize: 14, color: Colors.white)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset((sizeW - textPainter.width) / 2, (sizeH - textPainter.height) / 2));
  }
}
