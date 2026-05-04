import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class ComboDisplay extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  int comboCount = 0;
  double comboTimerRatio = 0.0;
  static const double comboX = 80;
  static const double comboY = 60;

  ComboDisplay() : super(anchor: Anchor.topCenter, position: Vector2(comboX, comboY));

  void updateCombo(int count) {
    comboCount = count;
    if (count > 0) comboTimerRatio = 1.0;
  }

  void updateComboTimer(double ratio) {
    comboTimerRatio = ratio.clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (comboCount < 2) return;

    final scale = 1.0 + comboTimerRatio * 0.3;
    final color = _comboColor(comboCount);

    final bgPaint = Paint()..color = Color.fromARGB(180, color.value >> 16 & 0xFF, color.value >> 8 & 0xFF, color.value & 0xFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, 90 * scale, 36 * scale),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    if (comboTimerRatio > 0 && comboTimerRatio < 1) {
      final timerPaint = Paint()
        ..color = Color.fromARGB(150, 255, 255, 255)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(4, 32 * scale - 4, (90 * scale - 8) * comboTimerRatio, 4),
          const Radius.circular(2),
        ),
        timerPaint,
      );
    }

    final fireText = _comboFireEmoji(comboCount);
    final tp = TextPainter(
      text: TextSpan(
        text: '$fireText ✕$comboCount',
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset((90 * scale - tp.width) / 2, (32 * scale - tp.height) / 2));

    if (comboCount >= 5) {
      final bonusTp = TextPainter(
        text: TextSpan(
          text: '+${_bonusPoints(comboCount)} pts',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      bonusTp.layout();
      bonusTp.paint(canvas, Offset((90 * scale - bonusTp.width) / 2, 32 * scale + 2));
    }
  }

  Color _comboColor(int count) {
    if (count >= 15) return const Color(0xFFE91E63);
    if (count >= 10) return const Color(0xFFFF5722);
    if (count >= 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  String _comboFireEmoji(int count) {
    if (count >= 15) return '🔥🔥🔥';
    if (count >= 10) return '🔥🔥';
    if (count >= 5) return '🔥';
    return '⚡';
  }

  int _bonusPoints(int combo) {
    if (combo >= 15) return 30;
    if (combo >= 10) return 25;
    if (combo >= 5) return 20;
    return 15;
  }
}
