import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

enum PowerUpType { fireball, explosive, shield, speedUp, extraLife }

class PowerUp extends PositionComponent with CollisionCallbacks {
  static const double powerUpSize = 25;
  static const double speed = 150;

  final PowerUpType type;
  late BallBounceGame gameRef;

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
    }
  }

  static String getIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.fireball:
        return 'F';
      case PowerUpType.explosive:
        return 'E';
      case PowerUpType.shield:
        return 'S';
      case PowerUpType.speedUp:
        return 'U';
      case PowerUpType.extraLife:
        return '+';
    }
  }
}
