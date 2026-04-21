import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class ComboDisplay extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  int comboCount = 0;
  double comboTimer = 0;
  static const double comboTimeout = 2.0;
  static const double comboX = 80;
  static const double comboY = 60;

  ComboDisplay() : super(anchor: Anchor.topCenter, position: Vector2(comboX, comboY));

  void onHit() {
    comboCount++;
    comboTimer = comboTimeout;
  }

  void reset() {
    comboCount = 0;
    comboTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) reset();
    }
  }

  @override
  void render(Canvas canvas) {
    if (comboCount < 2) return;
    final scale = 1.0 + (comboTimer / comboTimeout) * 0.2;
    final color = _comboColor(comboCount);
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, 80 * scale, 30 * scale), const Radius.circular(6)),
      paint,
    );
    final tp = TextPainter(
      text: TextSpan(text: '✖$comboCount', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((80 * scale - tp.width) / 2, (30 * scale - tp.height) / 2));
  }

  Color _comboColor(int count) {
    if (count >= 10) return const Color(0xFFE91E63);
    if (count >= 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }
}
