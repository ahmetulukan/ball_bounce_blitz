import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
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
  static const double _attackInterval = 2.0;
  static const double _bossSize = 80;
  int _attackCount = 0;

  // Charge attack
  bool _isCharging = false;
  double _chargeTimer = 0;
  Vector2 _chargeDir = Vector2.zero();

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
      if (_chargeTimer >= 1.0) {
        _isCharging = false;
      }
    }
  }

  void _chooseAttack() {
    _attackCount++;
    final pattern = _attackCount % 3;
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
    }
  }

  void _attackShoot() {
    // Spawn enemy projectiles (handled by game adding them)
    gameRef.add(BossProjectile(
      position: position.clone(),
      velocity: Vector2(0, 120),
    ));
    // Side projectiles
    gameRef.add(BossProjectile(
      position: position.clone() + Vector2(-30, 0),
      velocity: Vector2(-40, 100),
    ));
    gameRef.add(BossProjectile(
      position: position.clone() + Vector2(30, 0),
      velocity: Vector2(40, 100),
    ));
  }

  void _attackSweep() {
    final dir = position.x > 200 ? -1.0 : 1.0;
    position.x += dir * 150;
  }

  void _startCharge() {
    _isCharging = true;
    _chargeTimer = 0;
    _chargeDir = Vector2(0, 1);
  }

  void takeDamage(int amount) {
    health -= amount;
    if (health < 0) health = 0;
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
    for (int i = 0; i < 6; i++) {
      gameRef.add(ExplosionEffect(
        position: position.clone() + Vector2(
          (Random().nextDouble() - 0.5) * 80,
          (Random().nextDouble() - 0.5) * 60,
        ),
        count: 12,
        speed: 150,
      ));
    }
    gameRef.screenShake.shake(intensity: 12, duration: 0.5);
    gameRef.score += 200 * wave;
    gameRef.playSound('gameover');
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_phase * 2) * 3;
    final bodyColor = _isCharging
        ? const Color(0xFFFF4444)
        : const Color(0xFF9C27B0);

    // Glow
    final glowPaint = Paint()
      ..color = bodyColor.withAlpha(80)
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

    // Core
    final corePaint = Paint()..color = const Color(0xFFE91E63);
    canvas.drawCircle(Offset.zero, 18 + pulse, corePaint);

    // Eye
    final eyePaint = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(Offset(0, -8), 10, eyePaint);
    final pupilPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(Offset(0, -8), 5, pupilPaint);

    // Crown spikes
    final spikePaint = Paint()..color = const Color(0xFFFFD700);
    for (int i = 0; i < 3; i++) {
      final sx = -30.0 + i * 30.0;
      final path = Path()
        ..moveTo(sx, -_bossSize / 2)
        ..lineTo(sx + 12, -_bossSize / 2 - 20 - pulse)
        ..lineTo(sx + 24, -_bossSize / 2);
      canvas.drawPath(path, spikePaint);
    }

    // Health bar
    final barW = _bossSize;
    final barH = 6.0;
    final barY = _bossSize / 2 + 10;

    final bgPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-barW / 2, barY, barW, barH), bgPaint);

    final healthRatio = health / maxHealth;
    final hpPaint = Paint()
      ..color = healthRatio > 0.5
          ? const Color(0xFF4CAF50)
          : healthRatio > 0.25
              ? const Color(0xFFFFEB3B)
              : const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(-barW / 2, barY, barW * healthRatio, barH), hpPaint);
  }
}

class BossProjectile extends CircleComponent {
  static const double projectileRadius = 8;
  Vector2 velocity;
  double _life = 4.0;

  BossProjectile({required Vector2 position, required this.velocity})
      : super(
          radius: projectileRadius,
          position: position,
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    _life -= dt;
    if (_life <= 0 || position.y > 420) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFF4444).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, projectileRadius + 3, glowPaint);

    final paint = Paint()..color = const Color(0xFFFF4444);
    canvas.drawCircle(Offset.zero, projectileRadius, paint);
  }
}
