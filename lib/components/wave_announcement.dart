import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';

class WaveAnnouncement extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  double timer = 0;
  double duration = 1.8;
  int displayedWave = 1;
  bool active = false;

  WaveAnnouncement() : super(anchor: Anchor.center);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, size.y * 0.35);
  }

  void showWave(int wave) {
    displayedWave = wave;
    timer = duration;
    active = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (timer > 0) {
      timer -= dt;
      if (timer <= 0) active = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!active || timer <= 0) return;
    final progress = timer / duration;
    final scale = progress < 0.2 ? progress / 0.2 : 1.0;
    final alpha = progress < 0.3 ? progress / 0.3 : 1.0;

    final paint = Paint()..color = Color.fromARGB((alpha * 255).toInt(), 0, 188, 212);
    final shadowPaint = Paint()..color = Colors.black.withAlpha((alpha * 180).toInt());

    final text = 'WAVE $displayedWave';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 42 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.white.withAlpha((alpha * 255).toInt()),
          shadows: const [Shadow(color: Color(0x80000000), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

    if (displayedWave > 1) {
      final subText = 'Speed Up!';
      final sub = TextPainter(
        text: TextSpan(
          text: subText,
          style: TextStyle(
            fontSize: 18 * scale,
            color: const Color(0xFFFFEB3B).withAlpha((alpha * 255).toInt()),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      sub.layout();
      sub.paint(canvas, Offset(-sub.width / 2, tp.height / 2 + 4));
    }
  }
}
