import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';

class WaveDisplay extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  int wave = 1;
  int enemiesKilled = 0;
  int enemiesPerWave = 10;

  WaveDisplay() : super(anchor: Anchor.topRight, position: Vector2(0, 16));

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 16, 16);
  }

  void updateWave(int w, int killed, int total) {
    wave = w;
    enemiesKilled = killed;
    enemiesPerWave = total;
  }

  @override
  void render(Canvas canvas) {
    final bgPaint = Paint()..color = const Color(0x60000000);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 90, 40), const Radius.circular(8)),
      bgPaint,
    );

    final waveText = 'WAVE $wave';
    final tp = TextPainter(
      text: TextSpan(text: waveText, style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, const Offset(8, 4));

    // Progress bar
    final progress = enemiesPerWave > 0 ? (enemiesKilled / enemiesPerWave).clamp(0.0, 1.0) : 0.0;
    final barBg = Paint()..color = const Color(0x40FFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 22, 74, 6), const Radius.circular(3)), barBg);
    final barFill = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, 22, 74 * progress, 6), const Radius.circular(3)), barFill);
  }
}
