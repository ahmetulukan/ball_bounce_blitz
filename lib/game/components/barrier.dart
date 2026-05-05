import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart' show Colors;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

enum BarrierType { horizontal, vertical, angled, moving }

class Barrier extends PositionComponent with CollisionCallbacks {
  static const double barrierHeight = 12;
  
  late BallBounceGame gameRef;
  final BarrierType type;
  double speed = 0;
  double angle = 0;
  bool isActive = true;
  
  double _phase = 0;
  double _initialY = 0;

  Barrier({
    required Vector2 position,
    required this.type,
    this.angle = 0,
    this.speed = 0,
    double width = 80,
  }) : super(
          position: position,
          size: Vector2(width, barrierHeight),
          anchor: Anchor.center,
        ) {
    _initialY = position.y;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!isActive) return;
    
    _phase += dt * 2;
    
    // Moving barriers oscillate
    if (type == BarrierType.moving || speed != 0) {
      position.y = _initialY + sin(_phase) * 30;
      position.x += sin(_phase * 0.7) * speed * dt;
      
      // Keep in bounds
      position.x = position.x.clamp(size.x / 2, 400 - size.x / 2);
    }
  }

  void activate() {
    isActive = true;
  }

  void deactivate() {
    isActive = false;
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;
    
    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFF00BCD4).withAlpha(80)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.x + 6, height: size.y + 6),
        const Radius.circular(6),
      ),
      glowPaint,
    );
    
    // Main barrier
    final barrierPaint = Paint()..color = const Color(0xFF00BCD4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        const Radius.circular(4),
      ),
      barrierPaint,
    );
    
    // Center highlight
    final highlightPaint = Paint()..color = Colors.white.withAlpha(100);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, -2), width: size.x - 8, height: 3),
        const Radius.circular(2),
      ),
      highlightPaint,
    );
  }
}

class BarrierSpawner extends Component {
  late BallBounceGame gameRef;
  double _spawnTimer = 0;
  double _spawnInterval = 15.0; // Spawn every 15 seconds
  final Random _random = Random();
  final List<Barrier> _activeBarriers = [];
  int _waveThreshold = 3; // Start spawning after wave 3

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Only spawn barriers after certain wave
    if (gameRef.wave < _waveThreshold) return;
    if (gameRef.isPaused || gameRef.isGameOver) return;
    
    _spawnTimer += dt;
    
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnBarrier();
      
      // Remove old barriers
      _cleanupBarriers();
    }
  }

  void _spawnBarrier() {
    final types = [BarrierType.horizontal, BarrierType.moving, BarrierType.angled];
    final type = types[_random.nextInt(types.length)];
    
    double x;
    double y;
    double width;
    double angle = 0;
    double speed = 0;
    
    switch (type) {
      case BarrierType.horizontal:
        x = 60 + _random.nextDouble() * 280;
        y = 100 + _random.nextDouble() * 200;
        width = 60 + _random.nextDouble() * 60;
        break;
      case BarrierType.moving:
        x = 80 + _random.nextDouble() * 240;
        y = 120 + _random.nextDouble() * 150;
        width = 50 + _random.nextDouble() * 40;
        speed = 20 + _random.nextDouble() * 30;
        break;
      case BarrierType.angled:
        x = 100 + _random.nextDouble() * 200;
        y = 80 + _random.nextDouble() * 220;
        width = 70 + _random.nextDouble() * 50;
        angle = _random.nextBool() ? 0.3 : -0.3;
        break;
      default:
        x = 200;
        y = 150;
        width = 80;
    }
    
    final barrier = Barrier(
      position: Vector2(x, y),
      type: type,
      angle: angle,
      speed: speed,
      width: width,
    );
    barrier.gameRef = gameRef;
    
    _activeBarriers.add(barrier);
    gameRef.add(barrier);
    
    // Remove after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      barrier.removeFromParent();
      _activeBarriers.remove(barrier);
    });
  }

  void _cleanupBarriers() {
    _activeBarriers.removeWhere((b) => !b.isActive);
  }

  void reset() {
    _spawnTimer = 0;
    _activeBarriers.forEach((b) => b.removeFromParent());
    _activeBarriers.clear();
  }
}