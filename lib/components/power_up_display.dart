import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class PowerUpDisplay extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final Map<String, double> activeTimers = {};
  String? _flashMessage;
  double _flashTimer = 0;

  PowerUpDisplay() : super(anchor: Anchor.topRight, position: Vector2(0, 16));

  void addPowerUp(String label, double durationSeconds) {
    activeTimers[label] = durationSeconds;
  }

  void flash(String message) {
    _flashMessage = message;
    _flashTimer = 1.5;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x - 16, 16);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 16, 16);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) {
      _flashTimer -= dt;
      if (_flashTimer <= 0) _flashMessage = null;
    }
    activeTimers.removeWhere((k, v) {
      activeTimers[k] = v - dt;
      return activeTimers[k]! <= 0;
    });
  }

  @override
  void render(Canvas canvas) {
    // Flash message overlay
    if (_flashMessage != null && _flashTimer > 0) {
      final alpha = (_flashTimer * 180).clamp(0.0, 255.0).toInt();
      final paint = Paint()..color = const Color(0xFF00BCD4).withAlpha(alpha);
      final textPainter = TextPainter(
        text: TextSpan(text: _flashMessage, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final cx = (game.size.x - textPainter.width) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 8, -30, textPainter.width + 16, 26), const Radius.circular(6)),
        paint,
      );
      textPainter.paint(canvas, Offset(cx, -26));
    }

    int i = 0;
    for (final entry in activeTimers.entries) {
      final paint = Paint()..color = const Color(0xFF4CAF50).withAlpha(204);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, i * 28.0, 60, 24), const Radius.circular(4)), paint);

      final tp = TextPainter(text: TextSpan(text: '${entry.key}: ${entry.value.toStringAsFixed(1)}s', style: const TextStyle(color: Colors.white, fontSize: 11)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(4, i * 28.0 + 4));
      i++;
    }
  }
}