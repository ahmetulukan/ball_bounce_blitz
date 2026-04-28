import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import 'ball.dart';

class BossEnemy extends PositionComponent with HasGameReference<BallBounceBlitzGame>, CollisionCallbacks {
  double speed;
  int hits;
  int maxHits;
  final dynamic gameScene;
  static const double bossWidth = 80;
  static const double bossHeight = 80;
  bool _isDestroying = false;

  BossEnemy({
    required double x,
    required double y,
    required this.speed,
    required this.gameScene,
    int wave = 1,
  }) : hits = 3 + wave, maxHits = 3 + wave, super(anchor: Anchor.center) {
    position = Vector2(x, y);
    size = Vector2(bossWidth, bossHeight);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isDestroying) return;

    position.y += speed * dt;

    // Gentle horizontal oscillation
    if (position.x > 60 && position.x < game.size.x - 60) {
      position.x += (position.x < game.size.x / 2 ? 1.0 : -1.0) * 20 * dt;
    }

    if (position.y > game.size.y + 100) removeFromParent();
  }

  void takeHit(dynamic scene) {
    if (_isDestroying) return;
    hits--;
    
    if (hits <= 0) {
      _isDestroying = true;
      _playDestroyEffects(scene);
      removeFromParent();
    } else {
      scene?.shake();
      scene?.onPartialHit();
    }
  }

  void _playDestroyEffects(dynamic scene) {
    scene?.shake();
    // Spawn explosion particles
    for (int i = 0; i < 20; i++) {
      scene?.add(BossExplosionParticle(
        position: position.clone(),
        color: i % 2 == 0 ? const Color(0xFFFFD700) : const Color(0xFFE91E63),
      ));
    }
    scene?.onScore(200);
    scene?.onEnemyDestroyed();
    scene?.onBossDefeated();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      takeHit(gameScene);
      // Bounce ball
      if (intersectionPoints.isNotEmpty) {
        final hitPoint = intersectionPoints.first;
        final dx = (hitPoint.x - position.x).abs();
        final dy = (hitPoint.y - position.y).abs();
        if (dx > dy) {
          other.velocity = Vector2(-other.velocity.x, other.velocity.y);
        } else {
          other.velocity = Vector2(other.velocity.x, -other.velocity.y);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final hpRatio = hits / maxHits;

    // Shadow
    final shadowPaint = Paint()..color = Colors.black.withAlpha(50);
    canvas.drawRect(
      Rect.fromLTWH(-bossWidth / 2 + 4, -bossHeight / 2 + 4, bossWidth, bossHeight),
      shadowPaint,
    );

    // Body gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2A2A4E),
          const Color(0xFF1A1A2E),
        ],
      ).createShader(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2, bossWidth, bossHeight));
    canvas.drawRect(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2, bossWidth, bossHeight), bodyPaint);

    // Border glow
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2, bossWidth, bossHeight), borderPaint);

    // Inner circle pattern
    final innerPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset.zero, 18, innerPaint);
    final innerDarkPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawCircle(Offset.zero, 10, innerDarkPaint);

    // Crown
    final crownPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    _drawCrown(canvas, Offset(0, -8), 16, crownPaint);

    // HP bar background
    final hpBg = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2 - 14, bossWidth, 8), hpBg);
    
    // HP bar fill
    final hpFillColor = Color.lerp(const Color(0xFFE91E63), const Color(0xFF4CAF50), hpRatio)!;
    final hpFill = Paint()..color = hpFillColor;
    canvas.drawRect(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2 - 14, bossWidth * hpRatio, 8), hpFill);

    // HP bar shine
    final hpShine = Paint()..color = Colors.white.withAlpha(60);
    canvas.drawRect(Rect.fromLTWH(-bossWidth / 2, -bossHeight / 2 - 14, bossWidth * hpRatio, 3), hpShine);

    // Boss label
    final tp = TextPainter(
      text: TextSpan(
        text: 'BOSS',
        style: TextStyle(
          color: Colors.white.withAlpha(150),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, bossHeight / 2 - 14));
  }

  void _drawCrown(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx - size, center.dy + size * 0.5);
    path.lineTo(center.dx - size * 0.8, center.dy - size * 0.3);
    path.lineTo(center.dx - size * 0.4, center.dy + size * 0.1);
    path.lineTo(center.dx, center.dy - size * 0.5);
    path.lineTo(center.dx + size * 0.4, center.dy + size * 0.1);
    path.lineTo(center.dx + size * 0.8, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy + size * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }
}

class BossExplosionParticle extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  final Color color;
  double life = 0.5;
  late Vector2 velocity;
  double rotationSpeed = 0;

  BossExplosionParticle({required Vector2 position, required this.color}) : super(anchor: Anchor.center) {
    this.position = position;
    final angle = (DateTime.now().microsecond % 6283) / 1000.0;
    final speed = 100 + (DateTime.now().microsecond % 150).toDouble();
    velocity = Vector2(cos(angle) * speed, sin(angle) * speed);
    rotationSpeed = (DateTime.now().microsecond % 300) / 50 - 3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    velocity = velocity * 0.93;
    life -= dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 0.5).clamp(0.0, 1.0);
    final paint = Paint()..color = color.withAlpha((alpha * 255).toInt());
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 6, height: 6), paint);
  }
}