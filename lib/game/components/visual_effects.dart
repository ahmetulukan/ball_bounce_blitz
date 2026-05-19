import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

/// Visual effect: vignette overlay when player has low lives
class LowLifeVignette extends PositionComponent {
  late BallBounceGame gameRef;
  double _intensity = 0;
  
  LowLifeVignette() : super(priority: 1000);

  @override
  void update(double dt) {
    super.update(dt);
    // Intensity increases when lives are low
    if (gameRef.lives == 1) {
      _intensity = 0.4 + 0.1 * (0.5 + 0.5 * (1 + _pulsePhase));
    } else if (gameRef.lives == 2) {
      _intensity = 0.2;
    } else {
      _intensity = 0;
    }
    _pulsePhase += dt * 3;
  }

  double _pulsePhase = 0;

  @override
  void render(Canvas canvas) {
    if (_intensity <= 0) return;
    
    final pulse = (0.5 + 0.5 * (1 + _pulsePhase)) * _intensity;
    
    // Draw vignette on each corner
    final paint = Paint()
      ..color = Color(0xFFFF0000).withAlpha((pulse * 80).round().clamp(0, 80));
    
    // Simple corner darkness
    final rect = Rect.fromLTWH(0, 0, 400, 400);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        Colors.transparent,
        Color(0xFFFF0000).withAlpha((pulse * 100).round().clamp(0, 100)),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final rrect = RRect.fromRectAndRadius(rect, Radius.zero);
    canvas.drawRRect(
      rrect,
      Paint()..shader = gradient.createShader(rect),
    );
  }
}

/// Screen edge warning glow when boss wave
class BossWarningOverlay extends PositionComponent {
  late BallBounceGame gameRef;
  double _pulse = 0;
  static const double _maxAge = 3.0;
  double _age = 0;
  bool _active = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isBossWave && !_active) {
      _active = true;
      _age = 0;
    }
    if (_active) {
      _age += dt;
      _pulse = _age < _maxAge ? _age / _maxAge : 1.0;
      if (!gameRef.isBossWave) {
        _active = false;
        _age = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active || _pulse <= 0) return;
    
    final alpha = ((1 - _pulse) * 0.4 * (0.5 + 0.5 * (1 + _pulse * 10))).round().clamp(0, 255);
    final paint = Paint()..color = Color(0xFFE91E63).withAlpha(alpha);
    
    // Draw on all 4 edges
    canvas.drawRect(Rect.fromLTWH(0, 0, 400, 8), paint);
    canvas.drawRect(Rect.fromLTWH(0, 392, 400, 8), paint);
    canvas.drawRect(Rect.fromLTWH(0, 0, 8, 400), paint);
    canvas.drawRect(Rect.fromLTWH(392, 0, 8, 400), paint);
  }
}

/// Combo decay bar - shows time remaining on current combo
class ComboTimerBar extends PositionComponent {
  late BallBounceGame gameRef;
  static const double maxTime = 3.0;
  double _timeRemaining = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final combo = gameRef.comboSystem.currentCombo;
    if (combo > 0) {
      _timeRemaining = maxTime;
    } else {
      _timeRemaining = (_timeRemaining - dt).clamp(0, maxTime);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_timeRemaining <= 0) return;
    if (gameRef.comboSystem.currentCombo < 2) return;
    
    final ratio = _timeRemaining / maxTime;
    final barWidth = 100 * ratio;
    
    final bgPaint = Paint()..color = Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(150, 5, 100, 6),
        const Radius.circular(3),
      ),
      bgPaint,
    );
    
    final fillPaint = Paint()
      ..color = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF5722), 1 - ratio)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(150, 5, barWidth, 6),
        const Radius.circular(3),
      ),
      fillPaint,
    );
  }
}