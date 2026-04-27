import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../services/achievement_service.dart';

class AchievementPopup extends PositionComponent with HasGameReference {
  static const double popupWidth = 280;
  static const double popupHeight = 70;

  final Achievement achievement;
  final double startY;

  AchievementPopup({required this.achievement, required Vector2 position, required this.startY})
      : super(position: position, anchor: Anchor.center);

  double _elapsed = 0;
  static const double duration = 2.2;
  static const double flyUpDistance = 60;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = (_elapsed / duration).clamp(0.0, 1.0);

    // Fly up + fade
    position.y = startY - flyUpDistance * t;

    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration);
    final alpha = t < 0.2 ? (t / 0.2) : (1.0 - ((t - 0.8) / 0.2)).clamp(0.0, 1.0);

    final bgPaint = Paint()..color = Color.lerp(const Color(0xFFFFD700), const Color(0xFF1A1A2E), t)!.withAlpha((alpha * 255).toInt());
    final borderPaint = Paint()..color = Color.lerp(const Color(0xFFFFD700), Colors.transparent, t)!.withAlpha((alpha * 200).toInt());

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, popupWidth, popupHeight),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint..strokeWidth = 2);

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(text: achievement.icon, style: const TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(12, (popupHeight - iconPainter.height) / 2));

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: achievement.title,
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 255).toInt()),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(52, 14));

    // Description
    final descPainter = TextPainter(
      text: TextSpan(
        text: achievement.description,
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 180).toInt()),
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    descPainter.layout();
    descPainter.paint(canvas, Offset(52, 38));
  }
}
