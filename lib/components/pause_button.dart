import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PauseButton extends PositionComponent with HasGameReference, TapCallbacks {
  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x - 20, 20);
    size = Vector2(30, 30);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameRef is dynamic) {
      final g = gameRef as dynamic;
      if (g.overlays.contains('Pause')) {
        g.overlays.remove('Pause');
      } else {
        g.overlays.add('Pause');
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0x80FFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, 30, 30), const Radius.circular(6)), paint);
    final barPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(10, 8, 3, 14), barPaint);
    canvas.drawRect(Rect.fromLTWH(17, 8, 3, 14), barPaint);
  }
}