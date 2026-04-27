import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'ball.dart';

enum EnemyType { normal, fast, tough, big, shooter }

class Enemy extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  double speed;
  static const double baseWidth = 30;
  static const double baseHeight = 30;
  double width = baseWidth;
  double height = baseHeight;
  int hits = 1;
  int maxHits = 1;
  final EnemyType type;
  final dynamic gameScene;
  bool _isDestroying = false;
  double _flashTimer = 0;
  double _shootTimer = 0;

  Enemy({required double x, required double y, required this.speed, this.gameScene, this.type = EnemyType.normal})
      : super(anchor: Anchor.center) {
    position = Vector2(x, y);
    _applyType();
  }

  void _applyType() {
    switch (type) {
      case EnemyType.normal:
        width = 30; height = 30; hits = 1; maxHits = 1; speed = speed;
        break;
      case EnemyType.fast:
        width = 22; height = 22; hits = 1; maxHits = 1; speed = speed * 1.6;
        break;
      case EnemyType.tough:
        width = 35; height = 35; hits = 3; maxHits = 3; speed = speed * 0.7;
        break;
      case EnemyType.big:
        width = 50; height = 50; hits = 2; maxHits = 2; speed = speed * 0.5;
        break;
      case EnemyType.shooter:
        width = 32; height = 32; hits = 2; maxHits = 2; speed = speed * 0.6;
        break;
    }
    size = Vector2(width, height);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroying) return;
    if (_flashTimer > 0) _flashTimer -= dt;
    position.y += speed * dt;

    // Shooter enemy fires projectiles
    if (type == EnemyType.shooter) {
      _shootTimer += dt;
      if (_shootTimer >= 2.5) {
        _shootTimer = 0;
        _shoot();
      }
    }

    if (position.y > game.size.y + 60) removeFromParent();
  }

  void _shoot() {
    if (gameScene != null) {
      gameScene.add(EnemyProjectile(
        x: position.x,
        y: position.y,
        gameScene: gameScene,
      ));
    }
  }

  void takeHit(dynamic scene) {
    if (_isDestroying) return;
    hits--;
    if (hits <= 0) {
      _isDestroying = true;
      _playDestroyEffects(scene);
      removeFromParent();
    } else {
      _flashTimer = 0.1;
      scene?.onPartialHit();
      _spawnHitParticles();
    }
  }

  void _playDestroyEffects(dynamic scene) {
    scene?.shake();
    if (scene != null) {
      for (int i = 0; i < 8; i++) {
        scene.add(EnemyDestroyParticle(position: position.clone(), color: typeColor()));
      }
    }
    scene?.onScore(pointsForType());
    scene?.onEnemyDestroyed();
    scene?.triggerChainReaction(position, chainRadius);
  }

  int pointsForType() {
    switch (type) {
      case EnemyType.big: return 50;
      case EnemyType.tough: return 40;
      case EnemyType.fast: return 20;
      case EnemyType.shooter: return 35;
      case EnemyType.normal: return 25;
    }
  }

  double get chainRadius {
    switch (type) {
      case EnemyType.big: return 80.0;
      case EnemyType.tough: return 65.0;
      case EnemyType.fast: return 55.0;
      case EnemyType.shooter: return 60.0;
      case EnemyType.normal: return 60.0;
    }
  }

  void _spawnHitParticles() {
    if (gameScene != null) {
      gameScene.add(EnemyDestroyParticle(position: position.clone(), color: typeColor(), count: 4));
    }
  }

  @override
  void render(Canvas canvas) {
    final color = typeColor();
    final flashColor = _flashTimer > 0;
    
    // Draw shadow
    final shadowPaint = Paint()..color = Colors.black.withAlpha(40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-width / 2 + 2, -height / 2 + 2, width, height),
        const Radius.circular(4),
      ),
      shadowPaint,
    );

    // Main body
    final paint = Paint()..color = flashColor ? Colors.white : color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-width / 2, -height / 2, width, height), const Radius.circular(4)),
      paint,
    );

    // Gradient overlay
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha(40),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(-width / 2, -height / 2, width, height));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-width / 2, -height / 2, width, height), const Radius.circular(4)),
      gradPaint,
    );

    // Type-specific decorations
    _renderTypeDecoration(canvas);

    // HP pips for multi-hit enemies
    if (maxHits > 1) {
      final hpBgPaint = Paint()..color = Colors.black.withAlpha(100);
      canvas.drawRect(Rect.fromLTWH(-width / 2 + 4, -height / 2 - 10, width - 8, 5), hpBgPaint);
      final hpFillPaint = Paint()..color = _hpColor();
      canvas.drawRect(Rect.fromLTWH(-width / 2 + 4, -height / 2 - 10, (width - 8) * (hits / maxHits), 5), hpFillPaint);
    }
  }

  void _renderTypeDecoration(Canvas canvas) {
    switch (type) {
      case EnemyType.normal:
        // X mark
        _drawXMark(canvas, Colors.white.withAlpha(200));
        break;
      case EnemyType.fast:
        // Speed lines
        final linePaint = Paint()
          ..color = Colors.white.withAlpha(60)
          ..strokeWidth = 1.5;
        for (int i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(i * width * 0.25, height / 2 + 2),
            Offset(i * width * 0.25, height / 2 + 7),
            linePaint,
          );
        }
        break;
      case EnemyType.tough:
        // Shield icon
        _drawXMark(canvas, Colors.white.withAlpha(180));
        break;
      case EnemyType.big:
        // Crown symbol
        final crownPaint = Paint()..color = Colors.amber.withAlpha(200);
        final crownPath = Path()
          ..moveTo(-10, 5)
          ..lineTo(-10, -5)
          ..lineTo(-5, 0)
          ..lineTo(0, -8)
          ..lineTo(5, 0)
          ..lineTo(10, -5)
          ..lineTo(10, 5)
          ..close();
        canvas.drawPath(crownPath, crownPaint);
        break;
      case EnemyType.shooter:
        // Gun barrel icon
        final gunPaint = Paint()..color = Colors.amber.withAlpha(200);
        canvas.drawRect(Rect.fromLTWH(-3, height / 2 - 2, 6, 8), gunPaint);
        // Crosshair
        final crossPaint = Paint()..color = Colors.red.withAlpha(180);
        canvas.drawLine(
          Offset(-width / 2 + 4, -height / 2 + 4),
          Offset(width / 2 - 4, -height / 2 + 4),
          crossPaint..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(-width / 2 + 4, -height / 2 + 4),
          Offset(-width / 2 + 4, height / 2 - 4),
          crossPaint,
        );
        break;
    }
  }

  void _drawXMark(Canvas canvas, Color color) {
    final xp = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final margin = 5.0;
    canvas.drawLine(
      Offset(-width / 2 + margin, -height / 2 + margin),
      Offset(width / 2 - margin, height / 2 - margin),
      xp,
    );
    canvas.drawLine(
      Offset(width / 2 - margin, -height / 2 + margin),
      Offset(-width / 2 + margin, height / 2 - margin),
      xp,
    );
  }

  Color typeColor() {
    switch (type) {
      case EnemyType.normal: return const Color(0xFFE91E63);
      case EnemyType.fast: return const Color(0xFFFF5722);
      case EnemyType.tough: return const Color(0xFF3F51B5);
      case EnemyType.big: return const Color(0xFF9C27B0);
      case EnemyType.shooter: return const Color(0xFF795548);
    }
  }

  Color _hpColor() {
    final ratio = hits / maxHits;
    if (ratio > 0.6) return const Color(0xFF4CAF50);
    if (ratio > 0.3) return const Color(0xFFFF9800);
    return const Color(0xFFE91E63);
  }
}

/// Enemy projectile shot by shooter type enemies
class EnemyProjectile extends PositionComponent with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  static const double speed = 150;
  static const double size = 8;
  bool _hit = false;

  EnemyProjectile({required double x, required double y, required dynamic gameScene}) 
      : super(position: Vector2(x, y), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    size = Vector2(size * 2, size * 2);
    add(CircleHitbox(radius: size / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hit) return;
    position.y += speed * dt;
    if (position.y > game.size.y + 20) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_hit) return;
    if (other is Paddle) {
      _hit = true;
      (gameScene as dynamic)?.onProjectileHit();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Danger glow
    final glowPaint = Paint()..color = const Color(0x60F44336);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 + 3, glowPaint);

    // Main projectile
    final paint = Paint()..color = const Color(0xFFF44336);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Core
    final corePaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 4, corePaint);
  }
}

/// Particle spawned when enemy is destroyed
class EnemyDestroyParticle extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final Color color;
  final int count;
  double life = 0.4;
  late Vector2 velocity;
  double size = 4;

  EnemyDestroyParticle({required Vector2 position, required this.color, this.count = 8}) : super(anchor: Anchor.center) {
    this.position = position;
    final angle = (DateTime.now().microsecond % 6283) / 1000.0;
    final speed = 80 + (DateTime.now().microsecond % 120);
    velocity = Vector2(
      ((angle).cos() * speed),
      ((angle).sin() * speed),
    );
    size = 4 + (DateTime.now().microsecond % 4);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity = velocity * 0.92;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 0.4).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withAlpha((alpha * 255).toInt());
    canvas.drawCircle(Offset.zero, size * alpha, paint);
  }
}