import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Score popup that shows points earned with combo multiplier
class EnhancedScorePopup extends PositionComponent {
  final String text;
  final Color color;
  double _life = 0.8;
  double _vy = -80;
  double _scale = 1.0;
  final double baseScore;

  EnhancedScorePopup({
    required Vector2 position,
    required this.text,
    required this.color,
    this.baseScore = 0,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y += _vy * dt;
    _vy += 50 * dt;
    _scale = 1.0 + (0.3 * (_life / 0.8).clamp(0, 1));
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final alpha = (_life / 0.8 * 255).round();
    
    final shadowPaint = Paint()..color = Colors.black.withAlpha((alpha * 0.5).round());
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha(alpha),
          fontSize: 14 * _scale,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: shadowPaint.color, blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Combo multiplier popup - shows "x2", "x3" etc.
class ComboMultiplierPopup extends PositionComponent {
  final int combo;
  double _life = 0.6;
  double _scale = 0.5;
  static const double _pulseDuration = 0.15;

  ComboMultiplierPopup({
    required Vector2 position,
    required this.combo,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life > _pulseDuration) {
      _scale = 1.2 + 0.3 * ((_life - _pulseDuration) / _pulseDuration);
    } else {
      _scale = 1.2 + 0.3 * (_life / _pulseDuration);
    }
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final alpha = (_life / 0.6 * 255).round();
    
    final color = _getComboColor();
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'x$combo',
        style: TextStyle(
          color: color.withAlpha(alpha),
          fontSize: 16 * _scale,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }

  Color _getComboColor() {
    if (combo >= 20) return const Color(0xFFFF5722); // Fire orange
    if (combo >= 15) return const Color(0xFFFFD700); // Gold
    if (combo >= 10) return const Color(0xFFFF9800); // Orange
    if (combo >= 5) return const Color(0xFF03A9F4);  // Blue
    return const Color(0xFFFFFFFF); // White
  }
}

/// Critical hit text popup for chain lightning
class CriticalHitText extends PositionComponent {
  double _life = 0.7;
  double _scale = 0.8;
  double _yOffset = 0;

  CriticalHitText({required Vector2 position}) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _scale = 1.0 + (1 - _life / 0.7) * 0.5;
    _yOffset -= 60 * dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_life <= 0) return;
    final alpha = (_life / 0.7 * 255).round();
    
    // CRITICAL text with outline
    final outlinePaint = Paint()
      ..color = Color(0xFF000000).withAlpha(alpha)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..color = Color(0xFFFFD700).withAlpha(alpha)
      ..style = PaintingStyle.fill;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CRITICAL!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 12 * _scale,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2 + _yOffset));
  }
}

/// Power-up active indicator icons shown on HUD
class PowerUpActiveIndicators extends PositionComponent {
  late BallBounceGame gameRef;
  
  // Track active power-up timers
  Map<String, double> _activeTimers = {};
  static const double iconSize = 18;

  @override
  void update(double dt) {
    super.update(dt);
    _updateTimers(dt);
  }

  void _updateTimers(double dt) {
    // Fireball timer
    if (gameRef.ball.isFireball) {
      _activeTimers['fireball'] = 3.0;
    }
    
    // Shield timer  
    if (gameRef.ball.isShielded) {
      _activeTimers['shield'] = 5.0;
    }
    
    // Laser timer
    if (gameRef.ball.hasLaser) {
      _activeTimers['laser'] = 4.0;
    }
    
    // Energy shield timer
    if (gameRef.ball.hasEnergyShield) {
      _activeTimers['energyShield'] = 4.0;
    }
    
    // Freeze timer
    if (gameRef.ball.isFreezeTimeActive) {
      _activeTimers['freezeTime'] = 3.0;
    }

    // Decay all timers
    final toRemove = <String>[];
    for (final key in _activeTimers.keys.toList()) {
      _activeTimers[key] = _activeTimers[key]! - dt;
      if (_activeTimers[key]! <= 0) {
        toRemove.add(key);
      }
    }
    for (final k in toRemove) {
      _activeTimers.remove(k);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_activeTimers.isEmpty) return;
    
    double xOffset = 0;
    final yPos = 25.0;
    
    for (final entry in _activeTimers.entries) {
      final color = _getColor(entry.key);
      final ratio = (entry.value / _getMaxTime(entry.key)).clamp(0.0, 1.0);
      
      // Background circle
      final bgPaint = Paint()..color = Color(0xFF333333).withAlpha(200);
      canvas.drawCircle(Offset(xOffset + iconSize/2, yPos), iconSize/2 + 1, bgPaint);
      
      // Progress arc
      final arcPaint = Paint()
        ..color = color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(xOffset + iconSize/2, yPos), radius: iconSize/2 + 1),
        -pi/2,
        2 * pi * ratio,
        false,
        arcPaint,
      );
      
      // Icon text
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getIcon(entry.key),
          style: TextStyle(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xOffset + iconSize/2 - textPainter.width/2, yPos - textPainter.height/2),
      );
      
      xOffset += iconSize + 4;
    }
  }

  Color _getColor(String key) {
    switch (key) {
      case 'fireball': return const Color(0xFFFF5722);
      case 'shield': return const Color(0xFF03A9F4);
      case 'laser': return const Color(0xFF00FF00);
      case 'energyShield': return const Color(0xFF00E5FF);
      case 'freezeTime': return const Color(0xFF81D4FA);
      default: return Colors.white;
    }
  }

  String _getIcon(String key) {
    switch (key) {
      case 'fireball': return '🔥';
      case 'shield': return '🛡️';
      case 'laser': return '⚔️';
      case 'energyShield': return '🔵';
      case 'freezeTime': return '❄️';
      default: return '?';
    }
  }

  double _getMaxTime(String key) {
    switch (key) {
      case 'fireball': return 3.0;
      case 'shield': return 5.0;
      case 'laser': return 4.0;
      case 'energyShield': return 4.0;
      case 'freezeTime': return 3.0;
      default: return 1.0;
    }
  }
}
