import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

enum EnemyType { square, circle, triangle }
enum EnemyColorType { red, green, purple }

// Enemy behavior types
enum EnemyBehavior { normal, zigzag, fast, heavy }

class Enemy extends PositionComponent with CollisionCallbacks {
  static const double enemySize = 30;
  static const double baseSpeed = 100;

  late BallBounceGame gameRef;
  final EnemyType type;
  final EnemyColorType color;
  final EnemyBehavior behavior;
  double speed;
  final int points;
  final int hitCount; // for heavy enemies
  int _currentHits = 0;
  bool _isDestroyed = false;
  double _zigzagPhase = 0;
  double _initialX = 0;

  Enemy({
    required this.type,
    required this.color,
    this.speed = baseSpeed,
    this.points = 10,
    this.behavior = EnemyBehavior.normal,
    this.hitCount = 1,
  }) : super(
    size: Vector2(enemySize, enemySize),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
    _initialX = position.x;
    if (behavior == EnemyBehavior.zigzag) {
      _zigzagPhase = Random().nextDouble() * 2 * pi;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroyed) return;
    
    // Apply behavior-specific movement
    switch (behavior) {
      case EnemyBehavior.normal:
        position.y += speed * dt;
        break;
      case EnemyBehavior.zigzag:
        position.y += speed * dt;
        _zigzagPhase += dt * 3;
        position.x = _initialX + sin(_zigzagPhase) * 50;
        break;
      case EnemyBehavior.fast:
        position.y += speed * 1.8 * dt;
        break;
      case EnemyBehavior.heavy:
        position.y += speed * 0.7 * dt;
        break;
    }

    if (position.y > 430) {
      gameRef.loseLife();
      removeFromParent();
    }
  }

  // Returns true if enemy should be removed
  bool takeHit() {
    _currentHits++;
    if (_currentHits >= hitCount) {
      destroy();
      return true;
    }
    // Visual flash for heavy enemies when hit once
    return false;
  }

  void destroy() {
    if (_isDestroyed) return;
    _isDestroyed = true;
    gameRef.onEnemyDestroyed(this);
    removeFromParent();
  }

  Color get displayColor {
    // Flash white when heavy enemy takes a hit
    if (behavior == EnemyBehavior.heavy && _currentHits > 0) {
      return const Color(0xFFFFFFFF);
    }
    return getColor(color);
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
    final paint = Paint()..color = displayColor;
    
    switch (type) {
      case EnemyType.square:
        // Draw heavy indicator
        if (behavior == EnemyBehavior.heavy) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 3;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: enemySize + 6,
              height: enemySize + 6,
            ),
            paint,
          );
          paint.style = PaintingStyle.fill;
        }
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
        // Speed trail effect
        if (behavior == EnemyBehavior.fast) {
          final trailPaint = Paint()..color = displayColor.withAlpha(80);
          canvas.drawCircle(Offset(0, -8), enemySize / 3, trailPaint);
          canvas.drawCircle(Offset(0, -14), enemySize / 5, trailPaint);
        }
        break;
      case EnemyType.triangle:
        final path = Path();
        path.moveTo(0, -enemySize / 2);
        path.lineTo(enemySize / 2, enemySize / 2);
        path.lineTo(-enemySize / 2, enemySize / 2);
        path.close();
        canvas.drawPath(path, paint);
        // Zigzag indicator
        if (behavior == EnemyBehavior.zigzag) {
          final indicatorPaint = Paint()
            ..color = const Color(0xFFFFFFFF).withAlpha(150)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(Offset.zero, enemySize / 2 + 4, indicatorPaint);
        }
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
    
    // Determine behavior based on wave and random chance
    EnemyBehavior behavior = EnemyBehavior.normal;
    int hitCount = 1;
    
    if (wave >= 3) {
      final roll = _random.nextDouble();
      if (roll < 0.15) {
        behavior = EnemyBehavior.heavy;
        hitCount = 2;
      } else if (roll < 0.30) {
        behavior = EnemyBehavior.zigzag;
      } else if (roll < 0.40) {
        behavior = EnemyBehavior.fast;
      }
    } else if (wave >= 2) {
      final roll = _random.nextDouble();
      if (roll < 0.20) {
        behavior = EnemyBehavior.zigzag;
      } else if (roll < 0.30) {
        behavior = EnemyBehavior.fast;
      }
    }

    double baseEnemySpeed = Enemy.baseSpeed + (wave * 25);
    int basePoints = 10 + (wave * 5);
    
    // Behavior modifiers
    if (behavior == EnemyBehavior.heavy) basePoints = (basePoints * 1.5).round();
    if (behavior == EnemyBehavior.fast) basePoints = (basePoints * 1.2).round();
    if (behavior == EnemyBehavior.zigzag) basePoints = (basePoints * 1.3).round();
    
    final enemy = Enemy(
      type: type,
      color: color,
      speed: baseEnemySpeed,
      points: basePoints,
      behavior: behavior,
      hitCount: hitCount,
    );
    enemy.gameRef = game;
    enemy.position = Vector2(x, -Enemy.enemySize);
    return enemy;
  }
}