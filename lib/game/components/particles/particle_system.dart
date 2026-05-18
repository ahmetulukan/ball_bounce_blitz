import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

/// Manages pooled particles for performance
class ParticlePool extends Component {
  final int maxParticles;
  final List<ParticleNode> _pool = [];
  final Random _random = Random();

  ParticlePool({this.maxParticles = 200});

  @override
  Future<void> onLoad() async {
    // Pre-allocate particle pool
    for (int i = 0; i < maxParticles; i++) {
      _pool.add(ParticleNode());
    }
  }

  ParticleNode? acquire() {
    for (final node in _pool) {
      if (!node.active) {
        node.active = true;
        return node;
      }
    }
    return null;
  }

  void release(ParticleNode node) {
    node.active = false;
  }

  /// Spawn a burst of particles at a position
  void spawnBurst({
    required Vector2 position,
    required int count,
    required Color color,
    double speed = 100,
    double spread = 2 * pi,
    double angle = 0,
    double life = 0.5,
    double size = 4,
    bool glow = false,
  }) {
    for (int i = 0; i < count; i++) {
      final node = acquire();
      if (node == null) break;

      final a = angle + (_random.nextDouble() - 0.5) * spread;
      final spd = speed * (0.5 + _random.nextDouble() * 0.5);

      node.reset(
        position: position.clone(),
        velocity: Vector2(cos(a) * spd, sin(a) * spd),
        color: color,
        life: life * (0.5 + _random.nextDouble() * 0.5),
        size: size * (0.5 + _random.nextDouble() * 0.5),
        glow: glow,
      );

      add(node);
    }
  }

  /// Spawn a ring of particles
  void spawnRing({
    required Vector2 position,
    required int count,
    required Color color,
    double speed = 80,
    double life = 0.4,
    double size = 3,
  }) {
    for (int i = 0; i < count; i++) {
      final node = acquire();
      if (node == null) break;

      final angle = (i / count) * 2 * pi;
      node.reset(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: color,
        life: life,
        size: size,
        glow: false,
      );

      add(node);
    }
  }
}

/// A single particle node in the pool
class ParticleNode extends PositionComponent {
  Vector2 _velocity = Vector2.zero();
  Color _color = const Color(0xFFFFFFFF);
  double _life = 0.5;
  double _maxLife = 0.5;
  double _size = 4;
  bool _glow = false;
  bool active = false;

  ParticleNode() : super(anchor: Anchor.center);

  void reset({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double life,
    required double size,
    required bool glow,
  }) {
    this.position = position;
    _velocity = velocity;
    _color = color;
    _life = life;
    _maxLife = life;
    _size = size;
    _glow = glow;
    active = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;

    position += _velocity * dt;
    _velocity *= 0.96; // Decelerate
    _life -= dt;

    if (_life <= 0) {
      active = false;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;

    final alpha = (_life / _maxLife * 255).round().clamp(0, 255);
    final radius = _size * (_life / _maxLife);

    if (_glow) {
      final glowPaint = Paint()
        ..color = _color.withAlpha((alpha * 0.5).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset.zero, radius * 1.5, glowPaint);
    }

    final paint = Paint()..color = _color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

/// Background star particle for space theme
class BackgroundStar extends PositionComponent {
  final double twinkleSpeed;
  double _phase = 0;
  final double minSize;
  final double maxSize;

  BackgroundStar({
    required Vector2 position,
    this.twinkleSpeed = 2.0,
    this.minSize = 1,
    this.maxSize = 3,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * twinkleSpeed;
  }

  @override
  void render(Canvas canvas) {
    final alpha = (sin(_phase) * 0.3 + 0.7) * 200;
    final size = minSize + (sin(_phase * 0.7) * 0.5 + 0.5) * (maxSize - minSize);

    final paint = Paint()..color = const Color(0xFFFFFFFF).withAlpha(alpha.round());
    canvas.drawCircle(Offset.zero, size, paint);
  }
}

/// Meteor shower particle system
class MeteorShower extends Component {
  final Vector2 direction;
  final double speed;
  final int density;
  final Color color;
  double _spawnTimer = 0;
  final Random _random = Random();

  MeteorShower({
    Vector2? direction,
    this.speed = 200,
    this.density = 3,
    this.color = const Color(0xFFFF5722),
  }) : direction = direction ?? Vector2(0.3, 0.8);

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer += dt;

    if (_spawnTimer >= 0.1) {
      _spawnTimer = 0;

      for (int i = 0; i < density; i++) {
        final startX = _random.nextDouble() * 400;
        final meteor = MeteorParticle(
          position: Vector2(startX, -10),
          velocity: direction * speed * (0.8 + _random.nextDouble() * 0.4),
          color: color,
        );
        add(meteor);
      }
    }
  }
}

/// Individual meteor particle
class MeteorParticle extends PositionComponent {
  Vector2 _velocity;
  final Color color;
  double _trailTimer = 0;

  MeteorParticle({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
  }) : _velocity = velocity, super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;

    // Spawn trail particles
    _trailTimer += dt;
    if (_trailTimer >= 0.02) {
      _trailTimer = 0;
      
      // Add trail component
      final trail = MeteorTrail(
        position: position.clone(),
        color: color,
      );
      add(trail);
    }
  }

  @override
  void render(Canvas canvas) {
    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, 6, glowPaint);

    // Core
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset.zero, 4, paint);

    // Bright center
    final corePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, 2, corePaint);
  }
}

/// Trail left by meteor
class MeteorTrail extends PositionComponent {
  final Color color;
  double _life = 0.3;

  MeteorTrail({
    required Vector2 position,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 0.3 * 100).round().clamp(0, 100);
    final radius = _life / 0.3 * 6;

    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, radius, paint);
  }
}

/// Sparkle emitter for special effects
class SparkleEmitter extends Component {
  final Vector2 origin;
  final double emitRate; // particles per second
  final Color color;
  double _timer = 0;
  final Random _random = Random();
  double _radius = 30;
  bool _expanding = true;

  SparkleEmitter({
    required this.origin,
    this.emitRate = 20,
    this.color = const Color(0xFFFFD700),
  });

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    // Expand and contract radius
    if (_expanding) {
      _radius += dt * 20;
      if (_radius >= 50) _expanding = false;
    } else {
      _radius -= dt * 20;
      if (_radius <= 30) _expanding = true;
    }

    // Emit particles
    final emitInterval = 1.0 / emitRate;
    while (_timer >= emitInterval) {
      _timer -= emitInterval;
      _emitParticle();
    }
  }

  void _emitParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final dist = _radius * (0.5 + _random.nextDouble() * 0.5);
    final pos = origin + Vector2(cos(angle) * dist, sin(angle) * dist);

    final sparkle = _SparkleDot(
      position: pos,
      velocity: Vector2((_random.nextDouble() - 0.5) * 30, -50 - _random.nextDouble() * 50),
      color: color,
      life: 0.5 + _random.nextDouble() * 0.3,
    );
    add(sparkle);
  }
}

class _SparkleDot extends PositionComponent {
  Vector2 _velocity;
  final Color color;
  double _life;
  final double _maxLife;

  _SparkleDot({
    required Vector2 position,
    required Vector2 velocity,
    required this.color,
    required double life,
  }) : _velocity = velocity, _life = life, _maxLife = life, super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _velocity.y += 100 * dt; // Gentle gravity
    _life -= dt;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / _maxLife * 255).round().clamp(0, 255);
    final size = 2 + (_life / _maxLife) * 2;

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha((alpha * 0.5).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset.zero, size * 2, glowPaint);

    // Core
    final paint = Paint()..color = color.withAlpha(alpha);
    canvas.drawCircle(Offset.zero, size, paint);
  }
}