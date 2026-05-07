import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import '../ball_bounce_game.dart';

enum PowerUpType { fireball, explosive, shield, speedUp, extraLife, magnet }

class PowerUp extends PositionComponent with CollisionCallbacks {
  static const double powerUpSize = 25;
  static const double speed = 150;

  final PowerUpType type;
  late BallBounceGame gameRef;
  double _spin = 0;

  PowerUp({required this.type}) : super(
    size: Vector2(powerUpSize, powerUpSize),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * 3;
    position.y += speed * dt;

    if (position.y > 420) {
      removeFromParent();
    }
  }

  static PowerUp spawn(PowerUpType type, double x) {
    final powerUp = PowerUp(type: type);
    powerUp.position = Vector2(x, -powerUpSize);
    return powerUp;
  }

  static Color getColor(PowerUpType type) {
    switch (type) {
      case PowerUpType.fireball:
        return const Color(0xFFFF5722);
      case PowerUpType.explosive:
        return const Color(0xFFFFEB3B);
      case PowerUpType.shield:
        return const Color(0xFF03A9F4);
      case PowerUpType.speedUp:
        return const Color(0xFF9C27B0);
      case PowerUpType.extraLife:
        return const Color(0xFF4CAF50);
      case PowerUpType.magnet:
        return const Color(0xFFE91E63);
    }
  }

  static String getIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.fireball:
        return '🔥';
      case PowerUpType.explosive:
        return '💥';
      case PowerUpType.shield:
        return '🛡️';
      case PowerUpType.speedUp:
        return '⚡';
      case PowerUpType.extraLife:
        return '❤️';
      case PowerUpType.magnet:
        return '🧲';
    }
  }

  @override
  void render(Canvas canvas) {
    // Spin rotation for visual interest
    canvas.save();
    canvas.rotate(_spin * 0.3);
    
    // Glow background
    final glowPaint = Paint()
      ..color = getColor(type).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, powerUpSize / 2 + 2, glowPaint);
    
    // Outer rotating ring
    final ringPaint = Paint()
      ..color = getColor(type).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, powerUpSize / 2 + 5 + sin(_spin * 2) * 2, ringPaint);
    
    // Main circle
    final paint = Paint()..color = getColor(type);
    canvas.drawCircle(Offset.zero, powerUpSize / 2, paint);
    
    // Inner highlight
    final innerPaint = Paint()..color = Colors.white.withAlpha(80);
    canvas.drawCircle(Offset(-3, -3), powerUpSize / 4, innerPaint);
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, powerUpSize / 2, borderPaint);
    
    canvas.restore();
  }
}
