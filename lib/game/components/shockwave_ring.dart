import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Color, MaskFilter, BlurStyle;
import 'package:flame/components.dart';

/// Shockwave ring effect that expands outward from impact point
class ShockwaveRing extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double life;
  double _age = 0;

  ShockwaveRing({
    required Vector2 position,
    this.color = const Color(0xFF00BCD4),
    this.maxRadius = 60,
    this.life = 0.4,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 200;
    final radius = maxRadius * t;

    // Main ring
    final ringPaint = Paint()
      ..color = color.withAlpha(alpha.round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = (4 * (1.0 - t)).round().toDouble();
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    // Inner glow
    if (t < 0.5) {
      final innerAlpha = ((0.5 - t) / 0.5 * 80).round();
      final glowPaint = Paint()
        ..color = color.withAlpha(innerAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset.zero, radius * 0.6, glowPaint);
    }
  }
}

/// Triple shockwave for boss kills
class TripleShockwave extends PositionComponent {
  final double maxAge = 0.6;
  double _age = 0;
  final Color color;

  TripleShockwave({
    required Vector2 position,
    this.color = const Color(0xFFFFD700),
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Three rings at different phases
    add(_Ring(radiusMultiplier: 0.0, delay: 0.0, color: color));
    add(_Ring(radiusMultiplier: 0.3, delay: 0.1, color: color));
    add(_Ring(radiusMultiplier: 0.6, delay: 0.2, color: color));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }
}

class _Ring extends PositionComponent {
  final double radiusMultiplier;
  final double delay;
  final Color color;
  double _localAge = -999;

  _Ring({
    required this.radiusMultiplier,
    required this.delay,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _localAge = -delay;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _localAge += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_localAge < 0) return;
    final maxRadius = 80.0 + radiusMultiplier * 40;
    final life = 0.5;
    final t = (_localAge / life).clamp(0.0, 1.0);
    final alpha = (1.0 - t) * 200;
    final radius = maxRadius * t;

    final ringPaint = Paint()
      ..color = color.withAlpha(alpha.round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = (5 * (1.0 - t)).round().toDouble();
    canvas.drawCircle(Offset.zero, radius, ringPaint);
  }
}