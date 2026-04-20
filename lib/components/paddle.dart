import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class Paddle extends PositionComponent with HasGameRef<BallBounceBlitzGame>, DragCallbacks {
  static const double width = 80;
  static const double height = 15;
  double _dragX = 0;

  Paddle() : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    final gameSize = gameRef.size;
    position = Vector2(gameSize.x / 2, gameSize.y - 40);
    size = Vector2(width, height);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _dragX = event.localPosition.x;
    position.x += event.localDelta.x;
    position.x = position.x.clamp(width / 2, gameRef.size.x - width / 2);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF00BCD4);
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
  }
}