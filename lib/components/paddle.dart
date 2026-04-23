import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class Paddle extends PositionComponent with HasGameReference<BallBounceBlitzGame>, DragCallbacks {
  static const double baseWidth = 80;
  static const double paddleHeight = 15;
  static const double criticalZoneWidth = 15;
  double currentWidth = baseWidth;
  bool shielded = false;
  int shrinkLevel = 0;

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

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.x += event.localDelta.x;
    position.x = position.x.clamp(currentWidth / 2, game.size.x - currentWidth / 2);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, currentWidth, paddleHeight);
    if (shielded) {
      final glow = Paint()..color = const Color(0x4000BCD4);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(10)), glow);
    }
    
    // Draw critical zones on edges (gold color)
    final leftCritRect = Rect.fromLTWH(0, 0, criticalZoneWidth, paddleHeight);
    final rightCritRect = Rect.fromLTWH(currentWidth - criticalZoneWidth, 0, criticalZoneWidth, paddleHeight);
    final critPaint = Paint()..color = const Color(0xFFFF9800).withAlpha(150);
    canvas.drawRRect(RRect.fromRectAndRadius(leftCritRect, const Radius.circular(4)), critPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightCritRect, const Radius.circular(4)), critPaint);
    
    // Main paddle body
    final paint = Paint()..color = const Color(0xFF00BCD4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    final hi = Paint()..color = Colors.white.withAlpha(77);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, currentWidth, 4), const Radius.circular(4)), hi);
  }
}
