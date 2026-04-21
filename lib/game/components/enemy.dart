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
  bool _isDestroyed = false;

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
    if (_isDestroyed) return;
    position.y += speed * dt;

    if (position.y > 430) {
      gameRef.loseLife();
      removeFromParent();
    }
  }

  void destroy() {
    if (_isDestroyed) return;
    _isDestroyed = true;
    gameRef.onEnemyDestroyed(this);
    removeFromParent();
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

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = getColor(color);
    
    switch (type) {
      case EnemyType.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: enemySize,
            height: enemySize,
          ),
          paint,
        );
        break;
      case EnemyType.circle:
        canvas.drawCircle(Offset.zero, enemySize / 2, paint);
        break;
      case EnemyType.triangle:
        final path = Path();
        path.moveTo(0, -enemySize / 2);
        path.lineTo(enemySize / 2, enemySize / 2);
        path.lineTo(-enemySize / 2, enemySize / 2);
        path.close();
        canvas.drawPath(path, paint);
        break;
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