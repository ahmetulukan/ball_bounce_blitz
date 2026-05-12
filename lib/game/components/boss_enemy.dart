import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart' show Colors, TextStyle;
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'particles/explosion_particle.dart';
import 'ball.dart';
import 'paddle.dart';
import 'enemy.dart';
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
  double opacity = 1.0;

  // Phase tracking for behavior changes
  int _currentPhase = 0;
  static const int _maxPhases = 3;
  double _phaseTransitionTimer = 0;

  // Shield and barrier states
  bool _hasShield = false;
  double _shieldRotation = 0;
  int _shieldHits = 0;
  static const int _shieldMaxHits = 5;

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
    gameRef.enemyManager.registerBoss(this);

    // Boss gets shield at certain health thresholds
    if (wave >= 5 && health > 5) {
      _activateShield();
    }
  }

  void _activateShield() {
    _hasShield = true;
    _shieldHits = 0;
    _shieldRotation = 0;

    // Visual shield activation effect
    gameRef.add(BossShieldActivation(
      position: position.clone(),
      radius: _bossSize / 2 + 20,
    ));
  }

  void _deactivateShield() {
    _hasShield = false;
    _shieldHits = 0;

    // Shield shatter effect
    gameRef.add(ShieldShatterEffect(
      position: position.clone(),
      radius: _bossSize / 2 + 20,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isActive) return;

    _phase += dt * 2;
    _attackTimer += dt;
    _teleportTimer += dt;
    _phaseTransitionTimer += dt;
    _shieldRotation += dt * 2;

    // Phase transitions every 10 seconds or at health thresholds
    if (_phaseTransitionTimer >= 10 && _currentPhase < _maxPhases) {
      _advancePhase();
    }

    // Health-based phase change
    final healthRatio = health / maxHealth;
    if (healthRatio <= 0.3 && _currentPhase < _maxPhases - 1) {
      _advancePhase();
    }

    // Teleport check
    if (_teleportTimer >= _teleportInterval && !_isTeleporting && !_isCharging && _currentPhase >= 1) {
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

    // Horizontal drift - gets faster in later phases
    final driftSpeed = 40 + (_currentPhase * 15);
    position.x += sin(_phase * 0.7) * driftSpeed * dt;
    position.x = position.x.clamp(_bossSize / 2, 400 - _bossSize / 2);

    // Attack patterns - get more aggressive in later phases
    final attackIntervalMod = _currentPhase == 0 ? 1.0 : (_currentPhase == 1 ? 0.75 : 0.5);
    if (_attackTimer >= _attackInterval * attackIntervalMod) {
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

    // Update homing projectiles
    for (final projectile in _homingProjectiles) {
      if (!projectile.isRemoved) {
        projectile.update(dt);
      }
    }
    _homingProjectiles.removeWhere((p) => p.isRemoved);
  }

  void _advancePhase() {
    _currentPhase++;
    _phaseTransitionTimer = 0;

    // Activate shield in phase 2+
    if (_currentPhase >= 2 && !_hasShield && health > maxHealth * 0.3) {
      _activateShield();
    }

    // Boss speeds up
    speed = speed * 1.2;

    // Screen shake to signal phase change
    gameRef.screenShake.shake(intensity: 8, duration: 0.5);

    // Phase transition flash
    gameRef.add(BossPhaseTransition(
      position: position.clone(),
      phase: _currentPhase,
    ));
  }

  void _startTeleport() {
    _isTeleporting = true;
    _teleportPhase = 0;

    // Spawn teleport particles
    gameRef.add(TeleportParticles(
      position: position.clone(),
      count: 12,
    ));
  }

  void _chooseAttack() {
    _attackCount++;

    // More attack variety in later phases
    if (_currentPhase == 0) {
      // Phase 1: Simple horizontal shot
      _shootHorizontal();
    } else if (_currentPhase == 1) {
      // Phase 2: Spread shot
      final attacks = [_shootHorizontal, _shootSpread, _spawnMinion];
      attacks[Random().nextInt(attacks.length)]();
    } else {
      // Phase 3: Mix of all attacks
      final attacks = [_shootHorizontal, _shootSpread, _spawnMinion, _chargeAttack];
      attacks[Random().nextInt(attacks.length)]();
    }
  }

  void _shootHorizontal() {
    final projectile = BossProjectile(
      position: Vector2(position.x, position.y + _bossSize / 2),
      velocity: Vector2(0, 120),
      projectileSize: 12,
    );
    projectile.gameRef = gameRef;
    _homingProjectiles.add(projectile);
    gameRef.add(projectile);
  }

  void _shootSpread() {
    final angles = [-0.5, -0.25, 0, 0.25, 0.5];
    for (final angle in angles) {
      final vel = Vector2(sin(angle) * 100, cos(angle) * 120);
      final projectile = BossProjectile(
        position: Vector2(position.x, position.y + _bossSize / 2),
        velocity: vel,
        projectileSize: 10,
      );
      projectile.gameRef = gameRef;
      _homingProjectiles.add(projectile);
      gameRef.add(projectile);
    }
  }

  void _spawnMinion() {
    // Spawn a mini enemy from boss position
    if (gameRef.children.whereType<Enemy>().length < 5) {
      final random = Random();
      final enemy = Enemy(
        type: EnemyType.values[random.nextInt(EnemyType.values.length)],
        color: EnemyColorType.purple,
        speed: Enemy.baseSpeed * 1.5,
        points: 15,
        behavior: EnemyBehavior.fast,
        hitCount: 1,
      );
      enemy.gameRef = gameRef;
      enemy.position = Vector2(position.x + (random.nextDouble() - 0.5) * 40, position.y + _bossSize / 2);
      gameRef.add(enemy);
    }
  }

  void _chargeAttack() {
    if (_isCharging) return;

    // Charge towards ball
    final ballPos = gameRef.ball?.position ?? Vector2(200, 300);
    _chargeDir = (ballPos - position).normalized();
    _chargeDir.y = _chargeDir.y.abs(); // Always charge downward
    _isCharging = true;
    _chargeTimer = 0;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) async {
    super.onCollision(intersectionPoints, other);

    if (other is Ball) {
      // Check shield first
      if (_hasShield) {
        _shieldHits++;
        if (_shieldHits >= _shieldMaxHits) {
          _deactivateShield();
        }
        // Bounce ball
        final bounceDir = (other.position - position).normalized();
        other.velocity = bounceDir * other.speed * 0.8;
        gameRef.playSound('bounce');
        return;
      }

      // Normal hit
      _takeDamage();
      gameRef.screenShake.shake(intensity: 4, duration: 0.1);
      gameRef.add(ExplosionEffect(
        position: other.position.clone(),
        color: const Color(0xFF00BCD4),
        count: 6,
        speed: 100,
      ));

      // Bounce ball
      final bounceDir = (other.position - position).normalized();
      other.velocity = bounceDir * other.speed;
    }
  }

  void _takeDamage() {
    health--;
    if (health <= 0) {
      _onDefeated();
    }
  }

  void _onDefeated() {
    isActive = false;

    // Massive explosion
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (!isRemoved) {
          gameRef.add(ExplosionEffect(
            position: position.clone() + Vector2(
              (Random().nextDouble() - 0.5) * 40,
              (Random().nextDouble() - 0.5) * 40,
            ),
            color: const Color(0xFFFFD700),
            count: 15,
            speed: 150,
          ));
        }
      });
    }
    gameRef.screenShake.shake(intensity: 15, duration: 0.6);
    gameRef.score += 250 * wave;
    gameRef.enemyManager.unregisterBoss(this);
    gameRef.onBossDestroyed();
    gameRef.playSound('gameover');
    
    // Clear any remaining projectiles
    children.whereType<BossProjectile>().toList().forEach((p) => p.removeFromParent());
    
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;

    // Boss body based on wave/phase
    final bossColor = _getBossColor();

    // Outer glow
    final glowPaint = Paint()
      ..color = bossColor.withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, _bossSize / 2 + 8, glowPaint);

    // Main body
    final bodyPaint = Paint()..color = bossColor;
    canvas.drawCircle(Offset.zero, _bossSize / 2, bodyPaint);

    // Inner pattern (phase-dependent)
    _renderBossPattern(canvas, bossColor);

    // Shield visualization
    if (_hasShield) {
      _renderShield(canvas);
    }

    // Health bar above boss
    _renderHealthBar(canvas);

    // Phase indicator
    if (_currentPhase > 0) {
      _renderPhaseIndicator(canvas);
    }

    // Eye/face
    _renderBossFace(canvas, bossColor);
  }

  Color _getBossColor() {
    switch (_currentPhase) {
      case 0:
        return const Color(0xFF9C27B0); // Purple
      case 1:
        return const Color(0xFFE91E63); // Pink
      case 2:
        return const Color(0xFFFF5722); // Orange
      default:
        return const Color(0xFF9C27B0);
    }
  }

  void _renderBossPattern(Canvas canvas, Color baseColor) {
    final patternPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Concentric rings that pulse
    final pulse = sin(_phase * 2) * 3;
    for (int i = 1; i <= 3; i++) {
      final radius = (_bossSize / 2 - 10) * (i / 3) + pulse * (i / 3);
      canvas.drawCircle(Offset.zero, radius, patternPaint);
    }

    // Angular segments in later phases
    if (_currentPhase >= 1) {
      final segmentPaint = Paint()
        ..color = baseColor.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 4; i++) {
        final angle = (_phase * 0.5) + (i * pi / 2);
        final path = Path();
        path.moveTo(0, 0);
        path.lineTo(cos(angle) * _bossSize / 2, sin(angle) * _bossSize / 2);
        path.lineTo(cos(angle + 0.3) * _bossSize / 2, sin(angle + 0.3) * _bossSize / 2);
        path.close();
        canvas.drawPath(path, segmentPaint);
      }
    }
  }

  void _renderShield(Canvas canvas) {
    _shieldRotation += 0.02;
    final shieldPaint = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final shieldRadius = _bossSize / 2 + 15;
    canvas.drawCircle(Offset.zero, shieldRadius, shieldPaint);

    // Rotating shield segments
    for (int i = 0; i < 4; i++) {
      final startAngle = _shieldRotation + (i * pi / 2);
      final arcPaint = Paint()
        ..color = const Color(0xFF00BCD4).withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: shieldRadius),
        startAngle,
        pi / 3,
        false,
        arcPaint,
      );
    }

    // Shield health indicator
    final remainingRatio = (_shieldMaxHits - _shieldHits) / _shieldMaxHits;
    final healthArcPaint = Paint()
      ..color = const Color(0xFF00FF00).withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: shieldRadius + 5),
      0,
      2 * pi * remainingRatio,
      false,
      healthArcPaint,
    );
  }

  void _renderHealthBar(Canvas canvas) {
    final double barWidth = _bossSize + 20;
    final double barHeight = 8;
    final barY = -_bossSize / 2 - 20;

    // Background
    final bgPaint = Paint()..color = Colors.black54;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      bgPaint,
    );

    // Health fill
    final healthRatio = health / maxHealth;
    Color healthColor;
    if (healthRatio > 0.6) {
      healthColor = const Color(0xFF4CAF50);
    } else if (healthRatio > 0.3) {
      healthColor = const Color(0xFFFFEB3B);
    } else {
      healthColor = const Color(0xFFFF5722);
    }

    final healthPaint = Paint()..color = healthColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, barY, barWidth * healthRatio, barHeight),
        const Radius.circular(4),
      ),
      healthPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-barWidth / 2, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      borderPaint,
    );
  }

  void _renderPhaseIndicator(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚡' * _currentPhase,
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(180),
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, _bossSize / 2 + 5));
  }

  void _renderBossFace(Canvas canvas, Color baseColor) {
    final healthRatio = health / maxHealth;
    // Angry eyes
    final eyeY = -5.0;
    final eyeSpacing = 15.0;
    final eyeSize = 8.0;

    // Eye whites
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-eyeSpacing, eyeY), width: eyeSize * 1.5, height: eyeSize),
      eyeWhitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeSpacing, eyeY), width: eyeSize * 1.5, height: eyeSize),
      eyeWhitePaint,
    );

    // Pupils (follow ball)
    Vector2 pupilOffset = Vector2(0, 0);
    if (gameRef.ball != null) {
      final diff = gameRef.ball!.position - position;
      pupilOffset = diff.normalized() * 2;
    }
    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(-eyeSpacing + pupilOffset.x, eyeY + pupilOffset.y), 4, pupilPaint);
    canvas.drawCircle(Offset(eyeSpacing + pupilOffset.x, eyeY + pupilOffset.y), 4, pupilPaint);

    // Angry eyebrows
    final browPaint = Paint()
      ..color = baseColor.withAlpha(255)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-eyeSpacing - 8, eyeY - 10),
      Offset(-eyeSpacing + 5, eyeY - 6),
      browPaint,
    );
    canvas.drawLine(
      Offset(eyeSpacing + 8, eyeY - 10),
      Offset(eyeSpacing - 5, eyeY - 6),
      browPaint,
    );

    // Mouth
    if (_currentPhase >= 2 || healthRatio <= 0.3) {
      // Angry mouth
      final mouthPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      final mouthPath = Path();
      mouthPath.moveTo(-10, 10);
      mouthPath.quadraticBezierTo(0, 5, 10, 10);
      canvas.drawPath(mouthPath, mouthPaint);
    } else {
      // Neutral mouth
      final mouthPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;
      canvas.drawLine(Offset(-8, 10), Offset(8, 10), mouthPaint);
    }
  }
}

/// Boss projectile that tracks player
class BossProjectile extends PositionComponent with CollisionCallbacks {
  late BallBounceGame gameRef;
  Vector2 velocity;
  final double projectileSize;
  bool isRemoved = false;
  static const double homingStrength = 50;

  BossProjectile({
    required Vector2 position,
    required this.velocity,
    this.projectileSize = 12,
  }) : super(
          position: position,
          size: Vector2(projectileSize, projectileSize),
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

    // Slight homing towards ball
    if (gameRef.ball != null) {
      final diff = gameRef.ball!.position - position;
      if (diff.length > 0) {
        final homing = diff.normalized() * homingStrength * dt;
        velocity += homing;
        // Cap speed
        if (velocity.length > 200) {
          velocity = velocity.normalized() * 200;
        }
      }
    }

    position += velocity * dt;

    // Remove if off screen
    if (position.y > 450 || position.x < -20 || position.x > 420) {
      isRemoved = true;
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) async {
    super.onCollision(intersectionPoints, other);

    if (other is Ball) {
      gameRef.loseLife();
      isRemoved = true;
      removeFromParent();
    }

    if (other is Paddle) {
      gameRef.loseLife();
      isRemoved = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withAlpha(100)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, radius + 4, glowPaint);

    // Core
    final corePaint = Paint()..color = const Color(0xFFFF5722);
    canvas.drawCircle(Offset.zero, radius, corePaint);

    // Highlight
    final highlightPaint = Paint()..color = Colors.white.withAlpha(150);
    canvas.drawCircle(Offset(-radius / 2, -radius / 2), radius / 2, highlightPaint);
  }
}

/// Boss phase transition visual
class BossPhaseTransition extends PositionComponent {
  final int phase;
  double _life = 0.8;

  BossPhaseTransition({required Vector2 position, required this.phase})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.8 * 255).round().clamp(0, 255);
    final radius = (0.8 - _life) / 0.8 * 100;

    final ringPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚡ PHASE ${phase + 1}',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Shield activation burst
class BossShieldActivation extends PositionComponent {
  final double radius;
  double _life = 0.5;

  BossShieldActivation({required Vector2 position, required this.radius})
      : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.5 * 255).round().clamp(0, 255);

    final ringPaint = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset.zero, radius * (1 + (0.5 - _life) * 0.5), ringPaint);
  }
}

/// Shield shatter particles
class ShieldShatterEffect extends PositionComponent {
  final double radius;
  final Random _random = Random();
  double _life = 0.6;
  List<Vector2> _shards = [];

  ShieldShatterEffect({required Vector2 position, required this.radius})
      : super(position: position, anchor: Anchor.center) {
    for (int i = 0; i < 8; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      _shards.add(Vector2(cos(angle), sin(angle)) * (_random.nextDouble() * 100 + 50));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.6 * 255).round().clamp(0, 255);

    for (final shard in _shards) {
      final pos = shard * (1 - _life / 0.6);
      final paint = Paint()
        ..color = const Color(0xFF00BCD4).withAlpha(alpha)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, Offset(pos.x, pos.y), paint);
    }
  }
}

/// Teleport particle effect
class TeleportParticles extends PositionComponent {
  final int count;
  final Random _random = Random();
  double _life = 0.4;
  late List<Vector2> velocities;
  late List<double> sizes;

  TeleportParticles({required Vector2 position, required this.count})
      : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    velocities = [];
    sizes = [];
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 100 + 50;
      velocities.add(Vector2(cos(angle) * speed, sin(angle) * speed));
      sizes.add(_random.nextDouble() * 4 + 2);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.4 * 255).round().clamp(0, 255);

    for (int i = 0; i < count; i++) {
      final pos = velocities[i] * (1 - _life / 0.4);
      final paint = Paint()
        ..color = const Color(0xFF9C27B0).withAlpha(alpha);
      canvas.drawCircle(Offset(pos.x, pos.y), sizes[i], paint);
    }
  }
}