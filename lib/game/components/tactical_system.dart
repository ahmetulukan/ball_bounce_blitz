import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors;
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'power_up.dart';

/// Tactical feedback text that appears for strategic plays
class TacticalText extends PositionComponent {
  final String text;
  final Color color;
  final double life;
  double _age = 0;
  double _vy = -50;
  double _scale = 1.0;
  double _rotation = 0;

  TacticalText({
    required super.position,
    required this.text,
    this.color = const Color(0xFFFFFFFF),
    this.life = 1.2,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.94;
    _rotation += dt * 0.5;
    if (_age >= life * 0.6) {
      _scale = 1.0 - ((_age - life * 0.6) / (life * 0.4)) * 0.5;
    }
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_age < life * 0.8) 
        ? 255 
        : (1.0 - (_age - life * 0.8) / (life * 0.2)) * 255;
    
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(_rotation * 0.1);
    canvas.scale(_scale);

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round().clamp(0, 255))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha(alpha.round().clamp(0, 255)),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 4),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final bgRect = Rect.fromCenter(
      center: Offset.zero,
      width: textPainter.width + 24,
      height: textPainter.height + 12,
    );
    
    final bgPaint = Paint()
      ..color = const Color(0x88000000).withAlpha((alpha * 0.5).round().clamp(0, 128));
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, Radius.circular(8)), glowPaint);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    canvas.restore();
  }
}

/// Combo timer visualization ring around the ball
class ComboTimerRing extends PositionComponent with HasGameRef<BallBounceGame> {
  double _phase = 0;
  double _timerRatio = 0;

  ComboTimerRing();

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;

    if (gameRef.ball != null) {
      position = gameRef.ball.position.clone();
    }

    _timerRatio = gameRef.comboSystem.timerRatio;
  }

  @override
  void render(Canvas canvas) {
    if (_timerRatio <= 0 || gameRef.comboSystem.currentCombo < 3) return;

    final combo = gameRef.comboSystem.currentCombo;
    Color ringColor;
    if (combo >= 20) {
      ringColor = const Color(0xFFE91E63);
    } else if (combo >= 10) {
      ringColor = const Color(0xFFFF9800);
    } else {
      ringColor = const Color(0xFFFFD700);
    }

    // Background ring
    final bgPaint = Paint()
      ..color = ringColor.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, 20, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 20),
      -pi / 2,
      2 * pi * _timerRatio,
      false,
      progressPaint,
    );

    // Pulse effect at high combo
    if (combo >= 10) {
      final pulseRadius = 20 + sin(_phase) * 3;
      final pulsePaint = Paint()
        ..color = ringColor.withAlpha((80 + sin(_phase * 2) * 40).round().clamp(0, 120))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset.zero, pulseRadius, pulsePaint);
    }
  }
}

/// Power-up sequence tracker - shows recent power-up collections
class PowerUpSequenceTracker extends PositionComponent with HasGameRef<BallBounceGame> {
  final List<_SequenceEntry> _sequence = [];
  static const int maxEntries = 5;
  static const double entryLife = 4.0;
  double _phase = 0;

  PowerUpSequenceTracker();

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 2;

    // Remove expired entries
    _sequence.removeWhere((e) => e.age >= entryLife);
    for (final e in _sequence) {
      e.age += dt;
    }
  }

  void addPowerUp(PowerUpType type) {
    if (_sequence.length >= maxEntries) {
      _sequence.removeAt(0);
    }
    _sequence.add(_SequenceEntry(type: type, age: 0));
  }

  int get sequenceLength => _sequence.length;

  /// Check if last 3 power-ups match (gives bonus)
  bool hasRecentMatch() {
    if (_sequence.length < 3) return false;
    final last3 = _sequence.reversed.take(3).toList();
    return last3[0].type == last3[1].type && last3[1].type == last3[2].type;
  }

  @override
  void render(Canvas canvas) {
    if (_sequence.isEmpty) return;

    canvas.save();
    
    // Draw sequence at top of screen
    final startX = -(_sequence.length * 28) / 2 + 14;
    
    for (int i = 0; i < _sequence.length; i++) {
      final entry = _sequence[i];
      final x = startX + i * 28;
      final y = 0.0;
      
      // Fade out based on age
      final alpha = (1.0 - entry.age / entryLife) * 255;
      if (alpha <= 0) continue;
      
      final color = PowerUp.getColor(entry.type);
      
      // Glow
      final glowPaint = Paint()
        ..color = color.withAlpha((alpha * 0.4).round().clamp(0, 255))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), 10, glowPaint);
      
      // Background
      final bgPaint = Paint()
        ..color = const Color(0xFF1A1A2E).withAlpha((alpha * 0.9).round().clamp(0, 255));
      canvas.drawCircle(Offset(x, y), 10, bgPaint);
      
      // Border
      final borderPaint = Paint()
        ..color = color.withAlpha((alpha * 0.8).round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(x, y), 10, borderPaint);
      
      // Icon
      final icon = PowerUp.getIcon(entry.type);
      final iconPainter = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(canvas, Offset(x - iconPainter.width / 2, y - iconPainter.height / 2));
    }
    
    // Sequence match indicator
    if (hasRecentMatch()) {
      final matchAlpha = (sin(_phase * 3) * 0.3 + 0.7) * 255;
      final matchPaint = Paint()
        ..color = const Color(0xFFFFD700).withAlpha(matchAlpha.round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      
      // Draw connecting line
      final start = -(_sequence.length * 28) / 2;
      final end = -start;
      canvas.drawLine(Offset(start, 0), Offset(end, 0), matchPaint);
    }
    
    canvas.restore();
  }
}

class _SequenceEntry {
  final PowerUpType type;
  double age;

  _SequenceEntry({required this.type, required this.age});
}

/// Wave intensity meter - shows current wave difficulty
class WaveIntensityMeter extends PositionComponent with HasGameRef<BallBounceGame> {
  double _phase = 0;

  WaveIntensityMeter() : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    if (gameRef.isGameOver || gameRef.isPaused) return;

    final wave = gameRef.wave;
    final intensity = _calculateIntensity(wave);
    
    // Background bar
    final barWidth = 120.0;
    final barHeight = 8.0;
    final bgPaint = Paint()..color = const Color(0x33FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, 0, barWidth, barHeight),
        Radius.circular(4),
      ),
      bgPaint,
    );

    // Intensity fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4CAF50),
          const Color(0xFFFF9800),
          const Color(0xFFFF5722),
          const Color(0xFFE91E63),
        ],
        stops: [0.0, 0.33, 0.66, 1.0],
      ).createShader(Rect.fromLTWH(-barWidth / 2, 0, barWidth * intensity, barHeight));
    
    final fillWidth = barWidth * intensity;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, 0, fillWidth.clamp(0, barWidth), barHeight),
        Radius.circular(4),
      ),
      fillPaint,
    );

    // Pulse at high intensity
    if (intensity > 0.7) {
      final pulseAlpha = (sin(_phase * 4) * 0.3 + 0.5) * 255;
      final pulsePaint = Paint()
        ..color = const Color(0xFFE91E63).withAlpha(pulseAlpha.round().clamp(0, 255))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-barWidth / 2 - 2, -2, barWidth + 4, barHeight + 4),
          Radius.circular(6),
        ),
        pulsePaint,
      );
    }

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'WAVE $wave',
        style: TextStyle(
          color: Colors.white.withAlpha(180),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(-labelPainter.width / 2, barHeight + 4));
  }

  double _calculateIntensity(int wave) {
    if (wave <= 2) return 0.1 + wave * 0.05;
    if (wave <= 5) return 0.2 + (wave - 2) * 0.1;
    if (wave <= 10) return 0.5 + (wave - 5) * 0.06;
    if (wave <= 20) return 0.8 + (wave - 10) * 0.02;
    return 1.0;
  }
}

/// Strategic play announcer - shows tactical messages
class StrategicPlayAnnouncer extends PositionComponent with HasGameRef<BallBounceGame> {
  final Queue<_PlayMessage> _messageQueue = Queue();
  double _currentTimer = 0;
  static const double messageDuration = 2.0;
  static const double messageGap = 0.5;

  StrategicPlayAnnouncer() : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 60);
  }

  void enqueue(String text, {Color? color, String? icon}) {
    _messageQueue.add(_PlayMessage(
      text: text,
      color: color ?? const Color(0xFFFFFFFF),
      icon: icon,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_messageQueue.isEmpty) return;

    if (_currentTimer <= 0) {
      // Show next message
      final msg = _messageQueue.removeFirst();
      _showMessage(msg);
      _currentTimer = messageDuration;
    } else {
      _currentTimer -= dt;
    }
  }

  void _showMessage(_PlayMessage msg) {
    final widget = _StrategicMessageWidget(
      text: msg.text,
      color: msg.color,
      icon: msg.icon,
      onComplete: () {
        // Message animation complete
      },
    );
    // This would be added as an overlay in a real implementation
  }

  bool get hasMessages => _messageQueue.isNotEmpty;
}

class _PlayMessage {
  final String text;
  final Color color;
  final String? icon;

  _PlayMessage({required this.text, required this.color, this.icon});
}

class _StrategicMessageWidget extends StatelessWidget {
  final String text;
  final Color color;
  final String? icon;
  final VoidCallback onComplete;

  const _StrategicMessageWidget({
    required this.text,
    required this.color,
    this.icon,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.5 + value * 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x99000000),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(180), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Text(icon!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

