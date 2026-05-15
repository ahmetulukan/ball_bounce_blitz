import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';

/// Magnet attractor effect that orbits the ball when magnetized
class MagnetAttractor extends PositionComponent with HasGameReference {
  double _orbitAngle = 0;
  final double orbitRadius;
  final double orbitSpeed;
  final Color color;
  double _pulsePhase = 0;
  double _maxAge = 5.0;
  double _age = 0;

  MagnetAttractor({
    required Vector2 position,
    this.orbitRadius = 25,
    this.orbitSpeed = 3.0,
    this.color = const Color(0xFFE91E63),
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _orbitAngle += dt * orbitSpeed;
    _pulsePhase += dt * 8;
    _age += dt;

    if (_age >= _maxAge) {
      removeFromParent();
      return;
    }

    // Pulsing orbit radius
    final pulseRadius = orbitRadius + sin(_pulsePhase) * 3;
    
    // Calculate orbit position relative to parent (ball)
    final x = cos(_orbitAngle) * pulseRadius;
    final y = sin(_orbitAngle) * pulseRadius;
    position = Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    final fadeRatio = _age / _maxAge;
    final alpha = fadeRatio < 0.2 
        ? (fadeRatio / 0.2) // Fade in
        : (1.0 - (fadeRatio - 0.2) / 0.8); // Fade out
    final alphaInt = (alpha * 200).round().clamp(0, 200);
    
    final pulse = 1.0 + sin(_pulsePhase) * 0.15;
    final size = 8.0 * pulse;

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alphaInt * 0.5).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, size + 4, glowPaint);

    // Core
    final corePaint = Paint()..color = color.withAlpha(alphaInt);
    canvas.drawCircle(Offset.zero, size, corePaint);

    // Bright center
    final centerPaint = Paint()..color = Colors.white.withAlpha((alphaInt * 0.7).round());
    canvas.drawCircle(Offset.zero, size * 0.4, centerPaint);

    // Magnetic field lines
    for (int i = 0; i < 3; i++) {
      final lineAngle = _orbitAngle + (i * 2 * pi / 3);
      final lineStart = size + 2;
      final lineEnd = size + 8;
      
      final linePaint = Paint()
        ..color = color.withAlpha((alphaInt * 0.6).round())
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      
      final startX = cos(lineAngle) * lineStart;
      final startY = sin(lineAngle) * lineStart;
      final endX = cos(lineAngle) * lineEnd;
      final endY = sin(lineAngle) * lineEnd;
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }
  }
}