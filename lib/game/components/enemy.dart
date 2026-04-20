import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

enum EnemyType { square, circle, triangle }
enum EnemyColorType { red, green, purple }

class Enemy extends PositionComponent with CollisionCallbacks {
  static const double enemySize = 30;
  static const double baseSpeed = 100;

  late BallBounceGame gameRef;
  final EnemyType type;
  final EnemyColorType color;
  double speed;
  final int points;

  Enemy({
    required this.type,
    required this.color,
    this.speed = baseSpeed,
    this.points = 10,
  }) : super(
    size: Vector2(enemySize, enemySize),
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
      gameRef.loseLife();
      removeFromParent();
    }
  }

  static Enemy spawn(EnemyType type, EnemyColorType color, double x) {
    return Enemy(type: type, color: color);
  }

  static Color getColor(EnemyColorType color) {
    switch (color) {
      case EnemyColorType.red:
        return const Color(0xFFE53935);
      case EnemyColorType.green:
        return const Color(0xFF43A047);
      case EnemyColorType.purple:
        return const Color(0xFF8E24AA);
    }
  }
}

class EnemyFactory {
  static final Random _random = Random();

  static Enemy create(double x, int wave, BallBounceGame game) {
    final types = EnemyType.values;
    final colors = EnemyColorType.values;
    final type = types[_random.nextInt(types.length)];
    final color = colors[_random.nextInt(colors.length)];
    
    final enemy = Enemy(
      type: type,
      color: color,
      speed: Enemy.baseSpeed + (wave * 20),
      points: 10 + (wave * 5),
    );
    enemy.gameRef = game;
    enemy.position = Vector2(x, -Enemy.enemySize);
    return enemy;
  }
}