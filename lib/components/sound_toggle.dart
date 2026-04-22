import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../services/audio_manager.dart';

class SoundToggle extends PositionComponent {
  bool _muted = AudioManager.muted;

  SoundToggle({required super.position});

  @override
  Future<void> onLoad() async {
    size = Vector2(30, 30);
  }

  void toggle() {
    _muted = !_muted;
    AudioManager.toggleMute();
  }

  @override
  void onTapDown(TapDownEvent event) {
    toggle();
  }

  @override
  void render(Canvas canvas) {
    final icon = _muted ? '🔇' : '🔊';
    final paint = Paint()..color = const Color(0x80FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, 30, 30), const Radius.circular(6)),
      paint,
    );
    final tp = TextPainter(text: TextSpan(text: icon, style: const TextStyle(fontSize: 16)), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset((30 - tp.width) / 2, (30 - tp.height) / 2));
  }
}