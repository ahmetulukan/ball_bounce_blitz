import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color;
import '../ball_bounce_game.dart';
import 'enemy.dart';

/// Factory for creating enemies with various behaviors
class EnemyFactory {
  static final Random _random = Random();

  static Enemy create(double x, int difficultyLevel, BallBounceGame game) {
    final wave = game.wave;
    
    // Weighted random type selection based on difficulty
    final types = _getTypesForDifficulty(wave);
    final type = types[_random.nextInt(types.length)];
    
    // Determine behavior based on wave
    final behavior = _getBehaviorForWave(wave, difficultyLevel);
    
    // Color selection
    final colorIndex = _random.nextInt(EnemyColorType.values.length);
    final color = EnemyColorType.values[colorIndex];
    
    // Speed and points based on difficulty
    final baseSpeed = 80.0 + wave * 5 + difficultyLevel * 10;
    final speed = behavior == EnemyBehavior.fast
        ? baseSpeed * 1.8
        : behavior == EnemyBehavior.heavy
            ? baseSpeed * 0.7
            : baseSpeed;
    
    final points = behavior == EnemyBehavior.heavy
        ? 25
        : behavior == EnemyBehavior.fast
            ? 15
            : 10;
    
    final hitCount = behavior == EnemyBehavior.heavy ? 3 : 1;

    Enemy enemy;
    if (behavior == EnemyBehavior.splitting && wave >= 8) {
      enemy = _createSplittingEnemy(x, wave, color, baseSpeed, points);
    } else if (behavior == EnemyBehavior.shooting && wave >= 10) {
      enemy = _createShootingEnemy(x, wave, color, baseSpeed, points);
    } else {
      enemy = Enemy(
        type: type,
        color: color,
        behavior: behavior,
        speed: speed,
        points: points,
        hitCount: hitCount,
      );
    }

    enemy.position = Vector2(x, -Enemy.enemySize);
    return enemy;
  }

  static List<EnemyType> _getTypesForDifficulty(int wave) {
    if (wave < 3) {
      return [EnemyType.square, EnemyType.circle];
    } else if (wave < 6) {
      return [EnemyType.square, EnemyType.circle, EnemyType.triangle];
    } else if (wave < 10) {
      return [EnemyType.square, EnemyType.circle, EnemyType.triangle, EnemyType.diamond];
    } else {
      return EnemyType.values;
    }
  }

  static EnemyBehavior _getBehaviorForWave(int wave, int difficultyLevel) {
    if (wave < 2) return EnemyBehavior.normal;
    if (wave < 4) {
      final r = _random.nextDouble();
      if (r < 0.15) return EnemyBehavior.zigzag;
    }
    if (wave >= 5) {
      final r = _random.nextDouble();
      if (wave < 8) {
        if (r < 0.1) return EnemyBehavior.fast;
        if (r < 0.15) return EnemyBehavior.heavy;
      } else {
        if (r < 0.1) return EnemyBehavior.fast;
        if (r < 0.15) return EnemyBehavior.heavy;
        if (r < 0.2) return EnemyBehavior.splitting;
        if (r < 0.25) return EnemyBehavior.shooting;
      }
    }
    return EnemyBehavior.normal;
  }

  static Enemy _createSplittingEnemy(double x, int wave, EnemyColorType color, double speed, int points) {
    return Enemy(
      type: EnemyType.hexagon,
      color: color,
      behavior: EnemyBehavior.splitting,
      speed: speed * 1.2,
      points: points,
      hitCount: 2,
    );
  }

  static Enemy _createShootingEnemy(double x, int wave, EnemyColorType color, double speed, int points) {
    return Enemy(
      type: EnemyType.diamond,
      color: color,
      behavior: EnemyBehavior.shooting,
      speed: speed * 0.9,
      points: points + 5,
      hitCount: 1,
    );
  }
}

/// Spawn animation that creates a portal effect before enemy appears
class SpawnAnimation extends Component {
  final Vector2 spawnPosition;
  final Component Function() enemyFactory;
  final double delay = 0.3;
  double _timer = 0;
  bool _spawned = false;
  late BallBounceGame gameRef;

  SpawnAnimation({
    required this.spawnPosition,
    required this.enemyFactory,
  });

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    
    if (_timer >= delay && !_spawned) {
      _spawned = true;
      final enemy = enemyFactory();
      if (enemy is PositionComponent) {
        enemy.position = spawnPosition;
      }
      gameRef.add(enemy);
    }
    
    if (_timer >= delay + 0.1) {
      removeFromParent();
    }
  }
}

/// Enemy split effect when splitting enemy is destroyed
class EnemySplitEffect extends PositionComponent {
  final int childCount;
  final Color color;

  EnemySplitEffect({
    required Vector2 position,
    this.childCount = 2,
    this.color = const Color(0xFFFF5722),
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create child enemies that fly outward
    for (int i = 0; i < childCount; i++) {
      final angle = (i / childCount) * pi + pi / 2;
      // Children would be spawned here by the game logic
      // This effect is visual, actual child spawning handled in enemy destruction
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    removeFromParent();
  }
}