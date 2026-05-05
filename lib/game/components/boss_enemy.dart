import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Colors;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'particles/explosion_particle.dart';
import '../ball_bounce_game.dart';

class BossEnemy extends PositionComponent with CollisionCallbacks {
  late BallBounceGame gameRef;
  int health;
  int maxHealth;
  double speed;
  final int wave;
  bool isActive = true;
  bool get isDefeated => health <= 0;

  double _phase = 0;
  double _attackTimer = 0;
  static const double _attackInterval = 2.5;
  static const double _bossSize = 80;
  int _attackCount = 0;

  // Charge attack
  bool _isCharging = false;
  double _chargeTimer = 0;
  Vector2 _chargeDir = Vector2.zero();

  // Homing projectile tracking
  final List<BossProjectile> _homingProjectiles = [];

  // Teleport
  double _teleportTimer = 0;
  static const double _teleportInterval = 6.0;
  bool _isTeleporting = false;
  double _teleportPhase = 0;

  BossEnemy({
    required this.wave,
    this.health = 10,
    this.speed = 80,
    int? maxHealth,
  })  : maxHealth = maxHealth ?? (8 + wave ~/ 5 * 2),
        super(
          size: Vector2(_bossSize, _bossSize),
          anchor: Anchor.center,
        ) {
    health = this.maxHealth;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    _phase += dt * 2;
    _attackTimer += dt;
    _teleportTimer += dt;

    // Teleport check
    if (_teleportTimer >= _teleportInterval && !_isTeleporting && !_isCharging) {
      _startTeleport();
    }

    // Handle teleporting
    if (_isTeleporting) {
      _teleportPhase += dt * 4;
      // Dissolve effect
      if (_teleportPhase < pi) {
        // Fading out
        opacity = 1.0 - (_teleportPhase / pi);
      } else {
        // Reappearing at new position
        position = Vector2(
          50 + Random().nextDouble() * 300,
          60 + Random().nextDouble() * 60,
        );
        opacity = (_teleportPhase - pi) / pi;
        if (_teleportPhase >= 2 * pi) {
          _isTeleporting = false;
          _teleportPhase = 0;
          _teleportTimer = 0;
          opacity = 1.0;
        }
      }
      return;
    }

    // Gentle hover
    position.y = 60 + sin(_phase) * 8;

    // Horizontal drift
    position.x += sin(_phase * 0.7) * 40 * dt;
    position.x = position.x.clamp(_bossSize / 2, 400 - _bossSize / 2);

    // Attack patterns
    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _chooseAttack();
    }

    // Charge movement
    if (_isCharging) {
      _chargeTimer += dt;
      position += _chargeDir * speed * 3 * dt;
      // Keep in bounds
      position.x = position.x.clamp(_bossSize / 2, 400 - _bossSize / 2);
      position.y = position.y.clamp(_bossSize / 2, 200);
      
      if (_chargeTimer >= 1.0) {
        _isCharging = false;
        _chargeTimer = 0;
      }
    }
  }

  void _startTeleport() {
    _isTeleporting = true;
    _teleportPhase = 0;
    // Spawn warning effect
    gameRef.add(ExplosionEffect(
      position: position.clone(),
      color: const Color(0xFF9C27B0),
      count: 8,
      speed: 100,
    ));
    gameRef.screenShake.shake(intensity: 2, duration: 0.1);
  }

  void _chooseAttack() {
    _attackCount++;
    // Choose from 5 attack patterns based on wave
    final pattern = _attackCount % 5;
    switch (pattern) {
      case 0:
        _attackShoot();
        break;
      case 1:
        _attackSweep();
        break;
      case 2:
        _startCharge();
        break;
      case 3:
        _attackSpiral();
        break;
      case 4:
        _attackHoming();
        break;
    }
  }

  void _attackShoot() {
    // Spread shot - 5 projectiles in a fan
    for (int i = 0; i < 5; i++) {
      final angle = -0.5 + (i * 0.25);
      final vel = Vector2(sin(angle) * 80, cos(angle) * 120);
      final p = BossProjectile(
        position: position.clone(),
        velocity: vel,
      )..gameRef = gameRef;
      gameRef.add(p);
    }
  }

  void _attackSpiral() {
    // Spiral pattern - 8 projectiles around boss
    for (int i = 0; i < 8; i++) {
      final angle = _phase + (i * pi / 4);
      final vel = Vector2(cos(angle) * 60, sin(angle) * 40 + 80);
      final p = BossProjectile(
        position: position.clone(),
        velocity: vel,
      )..gameRef = gameRef;
      gameRef.add(p);
    }
  }

  void _attackHoming() {
    // Spawn a slow homing missile
    final p = BossProjectile(
      position: position.clone(),
      velocity: Vector2(0, 30),
      isHoming: true,
    )..gameRef = gameRef;
    gameRef.add(p);
  }

  void _attackSweep() {
    // Quick side-to-side movement with projectiles
    final dir = position.x > 200 ? -1.0 : 1.0;
    position.x += dir * 100;
    
    // Spawn projectiles during sweep
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!isDefeated) {
          final p = BossProjectile(
            position: position.clone(),
            velocity: Vector2(Random().nextDouble() * 60 - 30, 100),
          )..gameRef = gameRef;
          gameRef.add(p);
        }
      });
    }
  }

  void _startCharge() {
    _isCharging = true;
    _chargeTimer = 0;
    // Charge downward
    _chargeDir = Vector2(0, 1);
    
    // Warning effect
    gameRef.screenShake.shake(intensity: 3, duration: 0.2);
  }

  void takeDamage(int amount) {
    health -= amount;
    if (health < 0) health = 0;
    
    // Visual feedback
    _flashDamage();
  }

  double _damageFlash = 0;
  void _flashDamage() {
    _damageFlash = 1.0;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is! Ball) return;
    if (!isActive) return;

    takeDamage(1);
    gameRef.screenShake.shake(intensity: 3, duration: 0.1);
    gameRef.playSound('hit');

    if (isDefeated) {
      isActive = false;
      _onDefeated();
    }
  }

  void _onDefeated() {
    // Massive explosion
    for (int i = 0; i < 8; i++) {
      gameRef.add(ExplosionEffect(
        position: position.clone() + Vector2(
          (Random().nextDouble() - 0.5) * 100,
          (Random().nextDouble() - 0.5) * 80,
        ),
        count: 15,
        speed: 180,
      ));
    }
    gameRef.screenShake.shake(intensity: 15, duration: 0.6);
    gameRef.score += 250 * wave;
    gameRef.onBossDestroyed();
    gameRef.playSound('gameover');
    
    // Clear any remaining projectiles
    children.whereType<BossProjectile>().toList().forEach((p) => p.removeFromParent());
    
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_phase * 2) * 4;
    final bodyColor = _isCharging
        ? const Color(0xFFFF4444)
        : _damageFlash > 0
            ? Color.lerp(const Color(0xFF9C27B0), Colors.white, _damageFlash)!
            : const Color(0xFF9C27B0);

    // Damage flash decay
    _damageFlash *= 0.85;
    if (_damageFlash < 0.01) _damageFlash = 0;

    // Teleport effect
    if (_isTeleporting) {
      final alpha = _teleportPhase < pi 
          ? (1.0 - _teleportPhase / pi).clamp(0.0, 1.0)
          : ((_teleportPhase - pi) / pi).clamp(0.0, 1.0);
      
      final glowPaint = Paint()
        ..color = const Color(0xFF9C27B0).withAlpha((alpha * 150).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: _bossSize + 24, height: _bossSize + 24),
          const Radius.circular(16),
        ),
        glowPaint,
      );
    }

    // Glow
    final glowPaint = Paint()
      ..color = bodyColor.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: _bossSize + 16, height: _bossSize + 16),
        const Radius.circular(16),
      ),
      glowPaint,
    );

    // Body
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: _bossSize, height: _bossSize),
        const Radius.circular(12),
      ),
      bodyPaint,
    );

    // Core with pulsing
    final corePaint = Paint()..color = const Color(0xFFE91E63);
    canvas.drawCircle(Offset.zero, 20 + pulse, corePaint);

    // Eye that follows ball direction
    final ballPos = gameRef.ball.position;
    final lookDir = (ballPos - position).normalized();
    final eyeOffset = lookDir * 3;
    final eyePaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(eyeOffset.x, -8 + eyeOffset.y), 12, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(Offset(eyeOffset.x * 1.5, -8 + eyeOffset.y * 1.5), 6, pupilPaint);

    // Crown spikes with animation
    final spikePaint = Paint()..color = const Color(0xFFFFD700);
    for (int i = 0; i < 3; i++) {
      final sx = -36.0 + i * 36.0;
      final spikeHeight = 20 + sin(_phase * 3 + i) * 5;
      final path = Path()
        ..moveTo(sx, -_bossSize / 2)
        ..lineTo(sx + 15, -_bossSize / 2 - spikeHeight - pulse)
        ..lineTo(sx + 30, -_bossSize / 2);
      canvas.drawPath(path, spikePaint);
    }

    // Health bar with segments
    final barW = _bossSize;
    final barH = 8.0;
    final barY = _bossSize / 2 + 12;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF222222)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-barW / 2, barY, barW, barH), bgPaint);

    // Health segments
    final segmentCount = maxHealth;
    final segmentW = barW / segmentCount - 1;
    for (int i = 0; i < health; i++) {
      final hpRatio = health / maxHealth;
      final hpColor = hpRatio > 0.5
          ? const Color(0xFF4CAF50)
          : hpRatio > 0.25
              ? const Color(0xFFFFEB3B)
              : const Color(0xFFFF4444);
      final hpPaint = Paint()..color = hpColor;
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2 + i * (segmentW + 1), barY, segmentW, barH),
        hpPaint,
      );
    }

    // Attack indicator
    if (_isCharging) {
      final warningPaint = Paint()
        ..color = const Color(0xFFFF0000).withAlpha(100)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(-barW / 2, size.y / 2, barW, 400 - size.y / 2),
        warningPaint,
      );
    }
  }
}

class BossProjectile extends CircleComponent with CollisionCallbacks {
  static const double projectileRadius = 10;
  Vector2 velocity;
  double _life = 5.0;
  late BallBounceGame gameRef;
  bool isHoming = false;
  double _homingStrength = 0;

  BossProjectile({
    required Vector2 position,
    required this.velocity,
    this.isHoming = false,
  }) : super(
          radius: projectileRadius,
          position: position,
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Homing behavior
    if (isHoming && gameRef.isPaused == false) {
      final toBall = (gameRef.ball.position - position).normalized();
      velocity = Vector2.lerp(velocity.normalized(), toBall, _homingStrength.clamp(0, 0.5)) * velocity.length();
      _homingStrength += dt * 0.3;
    }
    
    position += velocity * dt;
    _life -= dt;
    if (_life <= 0 || position.y > 450 || position.x < -20 || position.x > 420) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Ball) {
      gameRef.loseLife();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Trail effect
    final trailPaint = Paint()
      ..color = const Color(0xFFFF4444).withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(-velocity.x * 0.02, -velocity.y * 0.02), projectileRadius * 0.8, trailPaint);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4444).withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, projectileRadius + 4, glowPaint);

    // Main body
    final paint = Paint()..color = isHoming ? const Color(0xFFFF00FF) : const Color(0xFFFF4444);
    canvas.drawCircle(Offset.zero, projectileRadius, paint);
    
    // Inner core
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, projectileRadius * 0.4, corePaint);
    
    // Homing indicator
    if (isHoming) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, projectileRadius + 4 + sin(_life * 10) * 2, ringPaint);
    }
  }
}