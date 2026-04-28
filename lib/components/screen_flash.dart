import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ScreenFlash extends PositionComponent with HasGameReference {
  Color flashColor;
  double duration;
  double elapsed = 0;
  double maxOpacity;

  @override
  Future<void> onLoad() async {
    size = game.size;
    priority = 1000; // render on top
  }

  ScreenFlash({
    required this.flashColor,
    this.duration = 0.3,
    this.maxOpacity = 0.4,
  });

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / duration;
    final opacity = (1 - progress) * maxOpacity;
    final paint = Paint()..color = flashColor.withAlpha((opacity * 255).clamp(0, 255).toInt());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}
