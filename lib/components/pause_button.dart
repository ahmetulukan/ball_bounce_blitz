import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class PauseButton extends PositionComponent with HasGameReference<BallBounceBlitzGame>, TapCallbacks {
  @override
  Future<void> onLoad() async {
    position = Vector2(game.size.x - 20, 20);
    size = Vector2(30, 30);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.overlays.toggle('Pause');
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
