import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class BarrierShard extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  late Vector2 velocity;
  double life = 0.5;
  static final Random _rand = Random();
  final double _angle;
  final double _speed;

  BarrierShard({required Vector2 position}) : _angle = (_rand.nextDouble() - 0.5) * 3.14, _speed = 80 + _rand.nextDouble() * 120, super(anchor: Anchor.center) {
    this.position = position;
    velocity = Vector2(_rand.nextDouble() * _speed * (_rand.nextBool() ? 1 : -1), -50 - _rand.nextDouble() * 80);
    size = Vector2(6, 6);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity.y += 250 * dt; // gravity
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 0.5).clamp(0.0, 1.0);
    final paint = Paint()..color = const Color(0xFF00BCD4).withAlpha((alpha * 255).toInt());
    canvas.save();
    canvas.rotate(_angle);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), paint);
    canvas.restore();
  }
}