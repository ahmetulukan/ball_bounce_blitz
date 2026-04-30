import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class ShockwaveEffect extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  double elapsed = 0;
  final double lifetime = 0.4;
  final Color color;
  final double maxRadius;

  ShockwaveEffect({
    required Vector2 position,
    this.color = const Color(0xFFFFEB3B),
    this.maxRadius = 80,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / lifetime;
    final radius = maxRadius * progress;
    final alpha = ((1 - progress) * 0.6).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withAlpha((alpha * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress);

    canvas.drawCircle(Offset.zero, radius, paint);
  }
}