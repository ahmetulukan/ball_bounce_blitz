import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class Star extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final double twinkleSpeed;
  double _phase;

  Star({required Vector2 pos, required this.twinkleSpeed, required double phase})
      : _phase = phase, super(position: pos, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * twinkleSpeed;
    if (_phase > 6.28) _phase -= 6.28;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (0.3 + 0.7 * ((sin(_phase) + 1) / 2)).clamp(0.0, 1.0);
    final paint = Paint()..color = Colors.white.withAlpha((alpha * 255).toInt());
    canvas.drawCircle(Offset.zero, 1.5, paint);
  }
}

class Starfield extends Component with HasGameReference<BallBounceBlitzGame> {
  final List<Star> stars = [];
  final Random _rand = Random();
  final int count;

  Starfield({this.count = 60});

  @override
  Future<void> onLoad() async {
    final gameSize = game.size;
    for (int i = 0; i < count; i++) {
      final pos = Vector2(_rand.nextDouble() * gameSize.x, _rand.nextDouble() * gameSize.y);
      final speed = 0.3 + _rand.nextDouble() * 1.5;
      final phase = _rand.nextDouble() * 6.28;
      stars.add(Star(pos: pos, twinkleSpeed: speed, phase: phase));
    }
    for (final s in stars) await add(s);
  }
}
