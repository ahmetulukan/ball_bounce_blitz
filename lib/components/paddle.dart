import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class Paddle extends PositionComponent with HasGameReference<BallBounceBlitzGame>, DragCallbacks {
  static const double baseWidth = 80;
  static const double paddleHeight = 15;
  static const double criticalZoneWidth = 15;
  double currentWidth = baseWidth;
  bool shielded = false;
  int shrinkLevel = 0;
  double _shieldFlashTimer = 0;

  bool isInCriticalZone(double hitX) {
    final leftEdge = position.x - currentWidth / 2;
    final rightEdge = position.x + currentWidth / 2;
    return (hitX <= leftEdge + criticalZoneWidth) || (hitX >= rightEdge - criticalZoneWidth);
  }

  Paddle() : super(anchor: Anchor.bottomCenter) {
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    position = Vector2(gameSize.x / 2, gameSize.y - 40);
    size = Vector2(currentWidth, paddleHeight);
  }

  void shrink() {
    shrinkLevel = (shrinkLevel + 1).clamp(0, 3);
    currentWidth = (baseWidth * (1 - shrinkLevel * 0.15)).clamp(40.0, baseWidth);
    size = Vector2(currentWidth, paddleHeight);
  }

  void onHit() {
    _shieldFlashTimer = 0.1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shieldFlashTimer > 0) _shieldFlashTimer -= dt;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x += event.localDelta.x;
    position.x = position.x.clamp(currentWidth / 2, game.size.x - currentWidth / 2);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, currentWidth, paddleHeight);

    // Shield glow
    if (shielded) {
      final glowPaint = Paint()
        ..color = _shieldFlashTimer > 0 ? Colors.white.withAlpha(100) : const Color(0x4000BCD4);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(5), const Radius.circular(12)), glowPaint);
    }

    // Main paddle body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF26C6DA),
          const Color(0xFF00BCD4),
          const Color(0xFF0097A7),
        ],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bodyPaint);

    // Highlight
    final hiPaint = Paint()..color = Colors.white.withAlpha(80);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, currentWidth, 4), const Radius.circular(4)), hiPaint);

    // Critical zones (edges)
    final leftCritRect = Rect.fromLTWH(0, 0, criticalZoneWidth, paddleHeight);
    final rightCritRect = Rect.fromLTWH(currentWidth - criticalZoneWidth, 0, criticalZoneWidth, paddleHeight);
    final critPaint = Paint()..color = const Color(0xFFFF9800).withAlpha(150);
    canvas.drawRRect(RRect.fromRectAndRadius(leftCritRect, const Radius.circular(4)), critPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightCritRect, const Radius.circular(4)), critPaint);

    // Shield icon if active
    if (shielded) {
      final shieldPaint = Paint()..color = Colors.white.withAlpha(150);
      // Simple shield shape
      final cx = currentWidth / 2;
      final path = Path()
        ..moveTo(cx, 2)
        ..lineTo(cx - 6, 5)
        ..lineTo(cx - 6, 10)
        ..quadraticBezierTo(cx, 13, cx + 6, 10)
        ..lineTo(cx + 6, 5)
        ..close();
      canvas.drawPath(path, shieldPaint);
    }
  }
}