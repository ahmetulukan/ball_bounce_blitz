import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'ball.dart';

enum EnemyType { normal, fast, tough, big }

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
    if (position.y > game.size.y + 60) removeFromParent();
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
    // Spawn particles
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
      case EnemyType.normal: return 25;
    }
  }

  double get chainRadius {
    switch (type) {
      case EnemyType.big: return 80.0;
      case EnemyType.tough: return 65.0;
      case EnemyType.fast: return 55.0;
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

    // X mark
    final xp = Paint()
      ..color = Colors.white.withAlpha(200)
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

    // HP pips for multi-hit enemies
    if (maxHits > 1) {
      final hpBgPaint = Paint()..color = Colors.black.withAlpha(100);
      canvas.drawRect(Rect.fromLTWH(-width / 2 + 4, -height / 2 - 10, width - 8, 5), hpBgPaint);
      final hpFillPaint = Paint()..color = _hpColor();
      canvas.drawRect(Rect.fromLTWH(-width / 2 + 4, -height / 2 - 10, (width - 8) * (hits / maxHits), 5), hpFillPaint);
    }

    // Fast enemy speed lines
    if (type == EnemyType.fast) {
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
    }
  }

  Color typeColor() {
    switch (type) {
      case EnemyType.normal: return const Color(0xFFE91E63);
      case EnemyType.fast: return const Color(0xFFFF5722);
      case EnemyType.tough: return const Color(0xFF3F51B5);
      case EnemyType.big: return const Color(0xFF9C27B0);
    }
  }

  Color _hpColor() {
    final ratio = hits / maxHits;
    if (ratio > 0.6) return const Color(0xFF4CAF50);
    if (ratio > 0.3) return const Color(0xFFFF9800);
    return const Color(0xFFE91E63);
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