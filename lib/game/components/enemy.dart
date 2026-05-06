import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';

enum EnemyType { square, circle, triangle, diamond, hexagon }
enum EnemyColorType { red, green, purple, gold }

// Enemy behavior types
enum EnemyBehavior { normal, zigzag, fast, heavy, splitting }

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
  double _pulsePhase = 0;

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
    
    _pulsePhase += dt * 4;
    
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
      case EnemyBehavior.splitting:
        position.y += speed * 1.2 * dt;
        break;
    }

    // Soft push away from other enemies
    _applyEnemySeparation();

    if (position.y > 430) {
      gameRef.loseLife();
      removeFromParent();
    }
  }

  void _applyEnemySeparation() {
    final allEnemies = gameRef.children.whereType<Enemy>().where((e) => e != this && !e._isDestroyed);
    for (final other in allEnemies) {
      final diff = position - other.position;
      final dist = diff.length;
      if (dist < enemySize * 1.5 && dist > 0) {
        final push = diff.normalized() * (enemySize * 1.5 - dist) * 0.5;
        position += push * 0.016; // per-frame nudge
      }
    }
  }

  // Returns true if enemy should be removed
  bool takeHit() {
    _currentHits++;
    if (_currentHits >= hitCount) {
      destroy();
      return true;
    }
    return false;
  }

  void destroy() {
    if (_isDestroyed) return;
    _isDestroyed = true;

    // Splitting enemies spawn 2 mini enemies on death
    if (behavior == EnemyBehavior.splitting) {
      _spawnSplitEnemies();
    }

    gameRef.onEnemyDestroyed(this);
    removeFromParent();
  }

  void _spawnSplitEnemies() {
    final types = [EnemyType.square, EnemyType.circle, EnemyType.triangle];
    for (int i = 0; i < 2; i++) {
      final splitType = types[i % types.length];
      final offsetX = (i == 0 ? -1.0 : 1.0) * 20;
      final mini = Enemy(
        type: splitType,
        color: color,
        speed: speed * 1.3,
        points: (points * 0.4).round(),
        behavior: EnemyBehavior.normal,
        hitCount: 1,
      );
      mini.gameRef = gameRef;
      mini.position = Vector2(position.x + offsetX, position.y);
      gameRef.add(mini);
    }
  }

  Color get displayColor {
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
      case EnemyColorType.gold:
        return const Color(0xFFFFD700);
    }
  }

  @override
  void render(Canvas canvas) {
    final basePaint = Paint()..color = displayColor;
    final pulseScale = 1.0 + sin(_pulsePhase) * 0.05;
    
    switch (type) {
      case EnemyType.square:
        if (behavior == EnemyBehavior.heavy) {
          basePaint.style = PaintingStyle.stroke;
          basePaint.strokeWidth = 3;
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: enemySize + 6,
              height: enemySize + 6,
            ),
            basePaint,
          );
          basePaint.style = PaintingStyle.fill;
        }
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: enemySize * pulseScale,
            height: enemySize * pulseScale,
          ),
          basePaint,
        );
        break;
      case EnemyType.circle:
        canvas.drawCircle(Offset.zero, enemySize / 2 * pulseScale, basePaint);
        if (behavior == EnemyBehavior.fast) {
          final trailPaint = Paint()..color = displayColor.withAlpha(80);
          canvas.drawCircle(Offset(0, -8), enemySize / 3, trailPaint);
          canvas.drawCircle(Offset(0, -14), enemySize / 5, trailPaint);
        }
        break;
      case EnemyType.triangle:
        final path = Path();
        final size = enemySize / 2 * pulseScale;
        path.moveTo(0, -size);
        path.lineTo(size, size);
        path.lineTo(-size, size);
        path.close();
        canvas.drawPath(path, basePaint);
        if (behavior == EnemyBehavior.zigzag) {
          final indicatorPaint = Paint()
            ..color = const Color(0xFFFFFFFF).withAlpha(150)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(Offset.zero, enemySize / 2 + 4, indicatorPaint);
        }
        break;
      case EnemyType.diamond:
        final path = Path();
        final size = enemySize / 2 * pulseScale;
        path.moveTo(0, -size);
        path.lineTo(size, 0);
        path.lineTo(0, size);
        path.lineTo(-size, 0);
        path.close();
        canvas.drawPath(path, basePaint);
        break;
      case EnemyType.hexagon:
        final path = Path();
        final size = enemySize / 2 * pulseScale;
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60 - 90) * pi / 180;
          final x = cos(angle) * size;
          final y = sin(angle) * size;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        
        if (behavior == EnemyBehavior.splitting) {
          final glowPaint = Paint()
            ..color = const Color(0xFFFFD700).withAlpha(100)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawPath(path, glowPaint);
        }
        
        canvas.drawPath(path, basePaint);
        break;
    }
    
    _renderBehaviorIndicator(canvas);
  }

  void _renderBehaviorIndicator(Canvas canvas) {
    switch (behavior) {
      case EnemyBehavior.heavy:
        if (hitCount > 1 && _currentHits < hitCount) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${hitCount - _currentHits}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        }
        break;
      case EnemyBehavior.fast:
        final trailPaint = Paint()
          ..color = displayColor.withAlpha(60)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(0, enemySize / 2), Offset(0, enemySize), trailPaint);
        canvas.drawLine(Offset(-5, enemySize / 2), Offset(-5, enemySize * 0.8), trailPaint);
        canvas.drawLine(Offset(5, enemySize / 2), Offset(5, enemySize * 0.8), trailPaint);
        break;
      case EnemyBehavior.splitting:
        final outlinePaint = Paint()
          ..color = Colors.white.withAlpha((150 + sin(_pulsePhase * 2) * 100).round().clamp(0, 255))
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset.zero, enemySize / 2 + 6, outlinePaint);
        break;
      default:
        break;
    }
  }
}

class EnemyFactory {
  static final Random _random = Random();

  static Enemy create(double x, int wave, BallBounceGame game) {
    final types = [EnemyType.square, EnemyType.circle, EnemyType.triangle, EnemyType.diamond, EnemyType.hexagon];
    final colors = [EnemyColorType.red, EnemyColorType.green, EnemyColorType.purple, EnemyColorType.gold];
    final type = types[_random.nextInt(types.length)];
    final color = colors[_random.nextInt(colors.length)];
    
    EnemyBehavior behavior = EnemyBehavior.normal;
    int hitCount = 1;
    
    if (wave >= 3) {
      final roll = _random.nextDouble();
      if (roll < 0.12) {
        behavior = EnemyBehavior.heavy;
        hitCount = 2;
      } else if (roll < 0.25) {
        behavior = EnemyBehavior.zigzag;
      } else if (roll < 0.35) {
        behavior = EnemyBehavior.fast;
      } else if (roll < 0.42) {
        behavior = EnemyBehavior.splitting;
      }
    } else if (wave >= 2) {
      final roll = _random.nextDouble();
      if (roll < 0.20) {
        behavior = EnemyBehavior.zigzag;
      } else if (roll < 0.30) {
        behavior = EnemyBehavior.fast;
      } else if (roll < 0.35) {
        behavior = EnemyBehavior.splitting;
      }
    }

    double baseEnemySpeed = Enemy.baseSpeed + (wave * 25);
    int basePoints = 10 + (wave * 5);
    
    if (behavior == EnemyBehavior.heavy) basePoints = (basePoints * 1.5).round();
    if (behavior == EnemyBehavior.fast) basePoints = (basePoints * 1.2).round();
    if (behavior == EnemyBehavior.zigzag) basePoints = (basePoints * 1.3).round();
    if (behavior == EnemyBehavior.splitting) basePoints = (basePoints * 2.0).round();
    
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
