import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

enum BossState { entering, active, charging, damaged, defeated }

class BossEnemy extends PositionComponent with HasGameRef {
  int health;
  int maxHealth;
  double speedMultiplier;
  int wave;
  BossState state = BossState.entering;
  bool isActive = true;
  bool get isDefeated => health <= 0;

  double _stateTimer = 0;
  double _attackTimer = 0;
  static const double _attackInterval = 2.5;
  static const double _chargeDuration = 1.5;

  bool _isCharging = false;
  double _pulsePhase = 0;
  int _lastHealth = 10;

  BossEnemy({
    required Vector2 position,
    this.speedMultiplier = 1.0,
    this.wave = 5,
    this.maxHealth = 10,
    this.health = 10,
  }) : super(
          position: position,
          size: Vector2(90, 70),
        ) {
    maxHealth = 8 + (wave ~/ 5) * 2;
    health = maxHealth;
    _lastHealth = health;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * 3;
    _stateTimer += dt;
    _attackTimer += dt;

    switch (state) {
      case BossState.entering:
        _updateEntering(dt);
        break;
      case BossState.active:
        _updateActive(dt);
        break;
      case BossState.charging:
        _updateCharging(dt);
        break;
      case BossState.damaged:
        _updateDamaged(dt);
        break;
      case BossState.defeated:
        break;
    }
  }

  void _updateEntering(double dt) {
    final targetY = gameRef.size.y * 0.25;
    if (position.y < targetY) {
      position.y += 60 * dt;
    } else {
      position.y = targetY;
      state = BossState.active;
      _stateTimer = 0;
    }
  }

  void _updateActive(double dt) {
    position.x += sin(_pulsePhase * 0.7) * 40 * dt;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);

    if (_attackTimer >= _attackInterval) {
      _attackTimer = 0;
      _chooseAttack();
    }
  }

  void _chooseAttack() {
    final attacks = ['shoot', 'sweep', 'charge'];
    final attack = attacks[DateTime.now().millisecond % attacks.length];

    switch (attack) {
      case 'shoot':
        _attackShoot();
        break;
      case 'sweep':
        _attackSweep();
        break;
      case 'charge':
        _startCharge();
        break;
    }
  }

  void _attackShoot() {
    state = BossState.damaged;
    _stateTimer = 0;
  }

  void _attackSweep() {
    final dir = position.x > gameRef.size.x / 2 ? -1.0 : 1.0;
    position.x += dir * 200;
    state = BossState.damaged;
    _stateTimer = 0;
  }

  void _startCharge() {
    _isCharging = true;
    state = BossState.charging;
    _stateTimer = 0;
  }

  void _updateCharging(double dt) {
    if (!_isCharging) return;

    if (_stateTimer < 0.5) return;

    if (_stateTimer < 0.5 + _chargeDuration) {
      final target = Vector2(gameRef.size.x / 2, gameRef.size.y * 0.6);
      final diff = target - position;
      if (diff.length > 5) {
        diff.normalize();
        position += diff * 300 * dt;
      }
    } else {
      _isCharging = false;
      state = BossState.damaged;
      _stateTimer = 0;
    }
  }

  void _updateDamaged(double dt) {
    if (_stateTimer >= 0.5) {
      state = BossState.active;
      _stateTimer = 0;
    }
  }

  void takeDamage(int amount) {
    health -= amount;
    if (health < 0) health = 0;
    _lastHealth = health;
  }

  @override
  void render(Canvas canvas) {
    final pulse = sin(_pulsePhase) * 3;
    final bodyColor = state == BossState.charging
        ? const Color(0xFFFF4444)
        : state == BossState.damaged
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF9C27B0);

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      bodyPaint,
    );

    final corePaint = Paint()
      ..color = const Color(0xFFE91E63)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      15 + pulse,
      corePaint,
    );

    final eyePaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2 - 5), 8, eyePaint);

    final pupilPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2 - 5), 4, pupilPaint);

    final barWidth = size.x;
    final barHeight = 6.0;
    final barX = 0.0;
    final barY = size.y + 8;

    final bgPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth, barHeight), bgPaint);

    final healthRatio = health / maxHealth;
    final healthPaint = Paint()
      ..color = healthRatio > 0.5
          ? const Color(0xFF4CAF50)
          : healthRatio > 0.25
              ? const Color(0xFFFFEB3B)
              : const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight), healthPaint);

    final spikePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final sx = 15 + i * 30.0;
      final path = Path()
        ..moveTo(sx, 0)
        ..lineTo(sx + 10, -18 - pulse)
        ..lineTo(sx + 20, 0);
      canvas.drawPath(path, spikePaint);
    }
  }

  Rect toRect() {
    return Rect.fromLTWH(
      position.x - size.x / 2,
      position.y - size.y / 2,
      size.x,
      size.y,
    );
  }
}
