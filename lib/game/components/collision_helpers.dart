import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../ball_bounce_game.dart';

/// Impact burst effect when ball hits enemy
class ImpactBurst extends PositionComponent {
  final Color color;
  final double maxAge;
  final int rays;
  double _age = 0;

  ImpactBurst({
    required Vector2 position,
    this.color = const Color(0xFFFFFFFF),
    this.maxAge = 0.25,
    this.rays = 8,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 255).round().clamp(0, 255);
    final radius = 10 + t * 30;

    // Draw radial rays
    for (int i = 0; i < rays; i++) {
      final angle = (i / rays) * 2 * pi;
      final inner = radius * 0.3;
      final outer = radius;

      final p1 = Offset(cos(angle) * inner, sin(angle) * inner);
      final p2 = Offset(cos(angle) * outer, sin(angle) * outer);

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..strokeWidth = 2 * (1 - t)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }
  }
}

/// Ripple effect for area impacts
class RippleEffect extends PositionComponent {
  final Color color;
  final double maxAge;
  double _age = 0;

  RippleEffect({
    required Vector2 position,
    this.color = const Color(0xFF2196F3),
    this.maxAge = 0.5,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 150).round().clamp(0, 255);

    // Multiple expanding rings
    for (int i = 0; i < 3; i++) {
      final ringT = ((t + i * 0.15) % 1.0);
      final ringRadius = ringT * 50;
      final ringAlpha = (1 - ringT) * alpha;

      final paint = Paint()
        ..color = color.withAlpha(ringAlpha.round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset.zero, ringRadius, paint);
    }
  }
}

/// Target reticle for aimed shots
class TargetReticle extends PositionComponent {
  double _rotation = 0;
  final double maxAge;
  double _age = 0;

  TargetReticle({
    required Vector2 position,
    this.maxAge = 1.0,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 3;
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 200).round().clamp(0, 255);
    final scale = 1.0 + t * 0.5;

    canvas.save();
    canvas.rotate(_rotation);
    canvas.scale(scale);

    final paint = Paint()
      ..color = const Color(0xFFFF0000).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Crosshair
    canvas.drawLine(Offset(-15, 0), Offset(-5, 0), paint);
    canvas.drawLine(Offset(5, 0), Offset(15, 0), paint);
    canvas.drawLine(Offset(0, -15), Offset(0, -5), paint);
    canvas.drawLine(Offset(0, 5), Offset(0, 15), paint);

    // Circle
    canvas.drawCircle(Offset.zero, 12, paint);

    // Center dot
    final dotPaint = Paint()
      ..color = const Color(0xFFFF0000).withAlpha(alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 2, dotPaint);

    canvas.restore();
  }
}

/// Trail segment for fast-moving objects
class TrailSegment extends PositionComponent {
  final Color color;
  double life;
  final double maxLife;
  final double width;

  TrailSegment({
    required Vector2 position,
    required this.color,
    this.life = 0.3,
    this.width = 4,
  }) : maxLife = life, super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / maxLife * 150).round().clamp(0, 150);
    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, width * (life / maxLife), paint);
  }
}

/// Zone indicator showing danger/safe areas
class ZoneIndicator extends PositionComponent {
  final Color color;
  final double maxAge;
  final bool isDanger;
  double _age = 0;

  ZoneIndicator({
    required Vector2 position,
    required this.size,
    this.color = const Color(0xFFFF5722),
    this.maxAge = 0.8,
    this.isDanger = true,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / maxAge).clamp(0.0, 1.0);
    final alpha = ((1 - t) * 100).round().clamp(0, 100);

    final paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y);
    canvas.drawRect(rect, paint);

    // Border
    final borderPaint = Paint()
      ..color = color.withAlpha((alpha * 2).round().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, borderPaint);
  }
}

/// Collision detection helper component
/// Attaches to any PositionComponent to detect collisions with specific types
class CollisionHelper extends Component with HasGameReference<BallBounceGame> {
  final Set<Type> _targetTypes = {};
  Function(PositionComponent, PositionComponent)? onCollisionEnter;
  Function(PositionComponent, PositionComponent)? onCollisionExit;

  final Set<PositionComponent> _colliding = {};

  CollisionHelper({List<Type>? targetTypes}) {
    if (targetTypes != null) {
      _targetTypes.addAll(targetTypes);
    }
  }

  void addTargetType(Type type) {
    _targetTypes.add(type);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check current collisions against target types
    // This is a lightweight helper - actual collision detection is handled by Flame
  }

  void notifyCollision(PositionComponent other, bool isEntering) {
    if (!_targetTypes.contains(other.runtimeType)) return;

    if (isEntering && !_colliding.contains(other)) {
      _colliding.add(other);
      onCollisionEnter?.call(this.parent as PositionComponent, other);
    } else if (!isEntering && _colliding.contains(other)) {
      _colliding.remove(other);
      onCollisionExit?.call(this.parent as PositionComponent, other);
    }
  }
}

/// Damage number popup
class DamageNumber extends PositionComponent {
  final int damage;
  final Color color;
  double life = 0.6;
  double _vy = -80;
  double _scale = 1.0;

  DamageNumber({
    required Vector2 position,
    required this.damage,
    this.color = const Color(0xFFFF0000),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y += _vy * dt;
    _vy += 100 * dt;
    _scale = 1.0 + (1 - life / 0.6) * 0.5;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (life <= 0) return;
    final alpha = (life / 0.6 * 255).round().clamp(0, 255);

    final text = damage > 0 ? '-$damage' : '+${-damage}';
    final textColor = damage > 0 ? color : const Color(0xFF4CAF50);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor.withAlpha(alpha),
          fontSize: 14 * _scale,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Color(0x88000000), blurRadius: 3),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}