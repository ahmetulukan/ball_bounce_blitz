import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import 'enemy.dart';
import 'effects.dart';
import 'particles/explosion_particle.dart';

/// Gravity Well - a powerful power-up that creates a vortex
/// that pulls in and destroys nearby enemies
class GravityWell extends PositionComponent with HasGameReference<BallBounceGame> {
  final double radius;
  final double pullStrength;
  final double duration;
  double _age = 0;
  double _rotation = 0;
  final Vector2 center;

  // Enemies currently being pulled
  final List<Enemy> _pulledEnemies = [];
  
  // Track if we dealt damage to an enemy this frame
  bool _hasDealtDamage = false;

  GravityWell({
    required this.center,
    this.radius = 120,
    this.pullStrength = 200,
    this.duration = 3.0,
  }) : super(
    position: center.clone(),
    anchor: Anchor.center,
    size: Vector2(radius * 2, radius * 2),
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Spawn the gravity well particle system
    gameRef.add(GravityWellParticles(
      position: position.clone(),
      radius: radius,
      life: duration,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _rotation += dt * 3;
    
    if (_age >= duration) {
      _collapseWell();
      removeFromParent();
      return;
    }

    // Pull nearby enemies toward center
    final enemies = gameRef.enemyManager.activeEnemies.toList();
    _hasDealtDamage = false;
    
    for (final enemy in enemies) {
      final diff = position - enemy.position;
      final dist = diff.length;
      
      if (dist < radius && dist > 5) {
        // Stronger pull for enemies closer to center
        final pullForce = pullStrength * (1.0 - dist / radius) * dt;
        enemy.position += diff.normalized() * pullForce;
        
        // Add pulled enemy to list
        if (!_pulledEnemies.contains(enemy)) {
          _pulledEnemies.add(enemy);
        }
        
        // Destroy enemies that get too close to center
        if (dist < 20 && !_hasDealtDamage) {
          _destroyEnemyAt(enemy);
          _hasDealtDamage = true;
        }
      }
    }
  }

  void _destroyEnemyAt(Enemy enemy) {
    // Extra visual effect for gravity destruction
    gameRef.add(ExplosionEffect(
      position: enemy.position.clone(),
      color: const Color(0xFF9C27B0),
      count: 12,
      speed: 150,
    ));
    
    gameRef.add(ShockwaveRing(
      position: enemy.position.clone(),
      color: const Color(0xFF9C27B0),
    ));
    
    // Award bonus points for gravity kills
    gameRef.score += enemy.points * 2;
    gameRef.comboSystem.onEnemyDestroyed(enemy);
    
    gameRef.enemyManager.unregisterEnemy(enemy);
    enemy.removeFromParent();
    
    // Floating bonus text
    gameRef.add(GravityKillBonus(
      position: enemy.position.clone(),
      points: enemy.points * 2,
    ));
  }

  void _collapseWell() {
    // Collapse effect - final implosion
    gameRef.add(GravityCollapseEffect(
      position: position.clone(),
    ));
  }

  @override
  void render(Canvas canvas) {
    final fade = (1.0 - _age / duration).clamp(0.0, 1.0);
    final pulse = 1.0 + sin(_rotation * 4) * 0.1;
    final collapseFactor = _age > duration * 0.8 
        ? (1.0 - (_age - duration * 0.8) / (duration * 0.2)).clamp(0.0, 1.0)
        : 1.0;

    // Outer danger zone ring
    final outerRing = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha((fade * 60 * collapseFactor).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, radius * pulse * collapseFactor, outerRing);

    // Spinning vortex lines
    for (int i = 0; i < 6; i++) {
      final angle = _rotation + (i * pi / 3);
      final innerR = 15.0 * collapseFactor;
      final outerR = (radius * 0.85) * pulse * collapseFactor;
      
      final path = Path();
      path.moveTo(cos(angle) * innerR, sin(angle) * innerR);
      
      // Spiral outward with curve
      for (double r = innerR; r < outerR; r += 5) {
        final spiralAngle = angle + (r / outerR) * pi * 0.5;
        path.lineTo(cos(spiralAngle) * r, sin(spiralAngle) * r);
      }
      
      final spiralPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFE91E63),
          const Color(0xFF9C27B0),
          (i / 6),
        )!.withAlpha((fade * 200 * collapseFactor).round())
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, spiralPaint);
    }

    // Event horizon - black center
    final coreSize = (20 + sin(_rotation * 8) * 5) * collapseFactor;
    final corePaint = Paint()
      ..color = const Color(0xFF1A1A2E).withAlpha((fade * 255 * collapseFactor).round());
    canvas.drawCircle(Offset.zero, coreSize, corePaint);

    // Core glow
    final glowPaint = Paint()
      ..color = const Color(0xFFE91E63).withAlpha((fade * 150 * collapseFactor).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset.zero, coreSize + 5, glowPaint);

    // Inner bright core
    final brightPaint = Paint()
      ..color = Colors.white.withAlpha((fade * 180 * collapseFactor).round());
    canvas.drawCircle(Offset.zero, coreSize * 0.4, brightPaint);

    // Pull indicators - lines toward pulled enemies
    for (final enemy in _pulledEnemies) {
      final diff = enemy.position - position;
      final dist = diff.length;
      if (dist < radius && dist > 20) {
        final lineAlpha = ((1.0 - dist / radius) * fade * 150 * collapseFactor).round().clamp(0, 255);
        final pullPaint = Paint()
          ..color = const Color(0xFFE91E63).withAlpha(lineAlpha)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset.zero, Offset(diff.x, diff.y), pullPaint);
      }
    }
  }
}

/// Particle system for gravity well visual
class GravityWellParticles extends PositionComponent with HasGameReference<BallBounceGame> {
  final double radius;
  final double life;
  final Random _random = Random();
  double _age = 0;

  GravityWellParticles({
    required Vector2 position,
    required this.radius,
    required this.life,
  }) : super(
    position: position,
    anchor: Anchor.center,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
      return;
    }

    // Spawn new particles
    if (_random.nextDouble() < 0.4) {
      _spawnParticle();
    }
  }

  void _spawnParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final dist = radius * 0.3 + _random.nextDouble() * radius * 0.7;
    
    final particle = GravityParticle(
      startPos: Vector2(
        position.x + cos(angle) * dist,
        position.y + sin(angle) * dist,
      ),
      targetPos: position.clone(),
      color: _random.nextBool() ? const Color(0xFFE91E63) : const Color(0xFF9C27B0),
      speed: 80 + _random.nextDouble() * 120,
      life: 0.8 + _random.nextDouble() * 0.4,
    );
    gameRef.add(particle);
  }

  @override
  void render(Canvas canvas) {
    // Nothing to render - particles handle themselves
  }
}

/// Individual gravity particle that spirals inward
class GravityParticle extends PositionComponent with HasGameReference<BallBounceGame> {
  final Vector2 startPos;
  final Vector2 targetPos;
  final Color color;
  final double speed;
  final double totalLife;
  double _age = 0;
  double _angle = 0;
  double _dist = 0;
  double _rotationSpeed = 0;

  GravityParticle({
    required this.startPos,
    required this.targetPos,
    required this.color,
    required this.speed,
    required this.totalLife,
  }) : super(
    position: startPos.clone(),
    anchor: Anchor.center,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    
    if (_age >= totalLife) {
      removeFromParent();
      return;
    }

    // Spiral inward
    _angle += _rotationSpeed * dt;
    _dist -= speed * dt;
    
    if (_dist < 5) {
      _dist = 5;
    }
    
    final dx = targetPos.x - position.x;
    final dy = targetPos.y - position.y;
    _rotationSpeed = (_random.nextDouble() - 0.5) * 2;
    
    position.x += dx * 3 * dt;
    position.y += dy * 3 * dt;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / totalLife).clamp(0.0, 1.0);
    final size = 3 + (1.0 - _age / totalLife) * 2;
    
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 100).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, size * 1.5, glowPaint);
    
    final paint = Paint()
      ..color = color.withAlpha((alpha * 255).round());
    canvas.drawCircle(Offset.zero, size, paint);
  }
}

/// Floating bonus text for gravity kills
class GravityKillBonus extends PositionComponent {
  final int points;
  final double life;
  double _age = 0;
  double _vy = -50;

  GravityKillBonus({
    required super.position,
    required this.points,
    this.life = 1.0,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y += _vy * dt;
    _vy *= 0.93;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _age / life).clamp(0.0, 1.0);
    final scale = 0.8 + (1.0 - _age / life) * 0.5;

    // Background pill
    final bgPaint = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha((alpha * 220).round());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 90 * scale,
          height: 30 * scale,
        ),
        Radius.circular(15 * scale),
      ),
      bgPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'GRAVITY +$points',
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 255).round()),
          fontSize: 13 * scale,
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

/// Gravity collapse effect when well expires
class GravityCollapseEffect extends PositionComponent with HasGameReference<BallBounceGame> {
  final double life;
  double _age = 0;

  GravityCollapseEffect({
    required Vector2 position,
    this.life = 0.5,
  }) : super(
    position: position,
    anchor: Anchor.center,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= life) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final collapse = (_age / life).clamp(0.0, 1.0);
    final alpha = (1.0 - collapse).clamp(0.0, 1.0);
    
    // Imploding rings
    for (int i = 0; i < 3; i++) {
      final ringRadius = 120 * (1.0 - collapse) * (1.0 + i * 0.2);
      final ringPaint = Paint()
        ..color = const Color(0xFFE91E63).withAlpha((alpha * 150).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = (4 * (1.0 - collapse)).clamp(0.5, 4.0);
      canvas.drawCircle(Offset.zero, ringRadius, ringPaint);
    }
    
    // Central flash
    if (collapse > 0.7) {
      final flashAlpha = ((1.0 - collapse) / 0.3 * 255).round().clamp(0, 255);
      final flashPaint = Paint()
        ..color = Colors.white.withAlpha(flashAlpha);
      canvas.drawCircle(Offset.zero, 30 * (1.0 - collapse), flashPaint);
    }
  }
}
