import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WaveProgressBar extends PositionComponent {
  int enemiesInWave;
  int enemiesDestroyed;
  static const double barWidth = 120;
  static const double barHeight = 8;

  WaveProgressBar({int enemiesInWave = 15}) : enemiesDestroyed = 0, super(priority: 10);

  void setProgress(int destroyed, int total) {
    enemiesDestroyed = destroyed;
    enemiesInWave = total;
  }

  @override
  void render(Canvas canvas) {
    final bgRect = Rect.fromLTWH(0, 0, barWidth, barHeight);
    final bgPaint = Paint()..color = const Color(0xFF333355);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);

    final progress = enemiesInWave > 0 ? (enemiesDestroyed / enemiesInWave).clamp(0.0, 1.0) : 0.0;
    final fillWidth = barWidth * progress;
    if (fillWidth > 0) {
      final fillPaint = Paint()..color = const Color(0xFF00BCD4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, fillWidth, barHeight), const Radius.circular(4)),
        fillPaint,
      );
    }

    // Boss marker at 100%
    if (progress >= 0.99) {
      final markerPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(barWidth, barHeight / 2), 4, markerPaint);
    }
  }
}
