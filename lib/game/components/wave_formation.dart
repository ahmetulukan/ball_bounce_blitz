import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'enemy.dart';
import '../ball_bounce_game.dart';

/// Special wave formation patterns for enhanced gameplay variety
enum WaveFormationType {
  vFormation,
  circleFormation,
  diagonalSweep,
  meteorShower,
  zigzagWall,
  spiralEntry,
}

/// WaveFormation - spawns enemies in special patterns
class WaveFormation extends Component {
  final WaveFormationType type;
  final int enemyCount;
  late BallBounceGame gameRef;
  final int wave;
  final double spawnDelay; // Delay between each enemy spawn in ms

  WaveFormation({
    required this.type,
    required this.enemyCount,
    required this.wave,
    this.spawnDelay = 200,
  });

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  /// Start spawning enemies in this formation
  void startSpawning() {
    switch (type) {
      case WaveFormationType.vFormation:
        _spawnVFormation();
        break;
      case WaveFormationType.circleFormation:
        _spawnCircleFormation();
        break;
      case WaveFormationType.diagonalSweep:
        _spawnDiagonalSweep();
        break;
      case WaveFormationType.meteorShower:
        _spawnMeteorShower();
        break;
      case WaveFormationType.zigzagWall:
        _spawnZigzagWall();
        break;
      case WaveFormationType.spiralEntry:
        _spawnSpiralEntry();
        break;
    }
  }

  void _spawnVFormation() {
    final centerX = 200.0;
    final startY = -30.0;
    final spacing = 35.0;
    
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay).round()), () {
        if (gameRef.isGameOver) return;
        
        final offset = i ~/ 2 + 1;
        final side = i.isEven ? -1 : 1;
        final x = centerX + (offset * spacing * side);
        final y = startY - (offset * spacing * 0.5);
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.position = Vector2(x, y);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  void _spawnCircleFormation() {
    final centerX = 200.0;
    final centerY = -50.0;
    final radius = 80.0;
    
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay).round()), () {
        if (gameRef.isGameOver) return;
        
        final angle = (i / enemyCount) * 2 * pi - pi / 2;
        final x = centerX + cos(angle) * radius;
        final y = centerY + sin(angle) * radius * 0.6;
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.position = Vector2(x, y);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  void _spawnDiagonalSweep() {
    final random = Random();
    
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay).round()), () {
        if (gameRef.isGameOver) return;
        
        // Diagonal from top-right to bottom-left or vice versa
        final fromRight = random.nextBool();
        final x = fromRight ? 380.0 : 20.0;
        final y = -20.0 - (i * 25);
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.position = Vector2(x, y);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  void _spawnMeteorShower() {
    final random = Random();
    
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay ~/ 2).round()), () {
        if (gameRef.isGameOver) return;
        
        // Random X positions, all coming from top with speed boost
        final x = 30.0 + random.nextDouble() * 340;
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.speed *= 1.5; // Faster meteors
        enemy.position = Vector2(x, -20.0 - random.nextDouble() * 50);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  void _spawnZigzagWall() {
    final wallWidth = 300.0;
    final startX = (400 - wallWidth) / 2;
    final spacing = wallWidth / (enemyCount - 1);
    
    // Spawn in two offset rows
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay).round()), () {
        if (gameRef.isGameOver) return;
        
        final x = startX + i * spacing;
        final y = -30.0 - (i.isOdd ? 40.0 : 0.0);
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.position = Vector2(x, y);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  void _spawnSpiralEntry() {
    final centerX = 200.0;
    final startY = -60.0;
    
    for (int i = 0; i < enemyCount; i++) {
      Future.delayed(Duration(milliseconds: (i * spawnDelay).round()), () {
        if (gameRef.isGameOver) return;
        
        final angle = (i / enemyCount) * 3 * pi; // 1.5 rotations
        final radius = 100.0 + (i * 10);
        final x = centerX + cos(angle) * radius * 0.5;
        final y = startY + (i * 30);
        
        final enemy = EnemyFactory.create(x, wave, gameRef);
        enemy.position = Vector2(x, y);
        enemy.gameRef = gameRef;
        gameRef.add(enemy);
      });
    }
  }

  /// Get a random formation for the given wave
  static WaveFormationType getRandomFormation(int wave) {
    final random = Random(wave);
    final formations = WaveFormationType.values;
    return formations[random.nextInt(formations.length)];
  }

  /// Get formation name for display
  static String getFormationName(WaveFormationType type) {
    switch (type) {
      case WaveFormationType.vFormation:
        return 'V Formation';
      case WaveFormationType.circleFormation:
        return 'Circle Formation';
      case WaveFormationType.diagonalSweep:
        return 'Diagonal Sweep';
      case WaveFormationType.meteorShower:
        return 'Meteor Shower';
      case WaveFormationType.zigzagWall:
        return 'Zigzag Wall';
      case WaveFormationType.spiralEntry:
        return 'Spiral Entry';
    }
  }

  /// Get formation icon for display
  static String getFormationIcon(WaveFormationType type) {
    switch (type) {
      case WaveFormationType.vFormation:
        return '🔺';
      case WaveFormationType.circleFormation:
        return '⭕';
      case WaveFormationType.diagonalSweep:
        return '📐';
      case WaveFormationType.meteorShower:
        return '☄️';
      case WaveFormationType.zigzagWall:
        return '〰️';
      case WaveFormationType.spiralEntry:
        return '🌀';
    }
  }
}

/// Formation announcement overlay text
class FormationAnnouncement extends PositionComponent {
  final WaveFormationType formationType;
  double _life = 2.0;
  double _phase = 0;

  FormationAnnouncement({
    required Vector2 position,
    required this.formationType,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 3;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 2.0 * 255).round().clamp(0, 255);
    final scale = 0.8 + (1.0 - _life / 2.0) * 0.4;
    final yOffset = sin(_phase) * 5;

    canvas.save();
    canvas.translate(0, yOffset);

    // Background glow
    final glowPaint = Paint()
      ..color = const Color(0xFF9C27B0).withAlpha(alpha ~/ 3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 200 * scale, height: 50 * scale),
        Radius.circular(12 * scale),
      ),
      glowPaint,
    );

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withAlpha((alpha * 0.8).round());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 200 * scale, height: 50 * scale),
        Radius.circular(12 * scale),
      ),
      bgPaint,
    );

    // Icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: WaveFormation.getFormationIcon(formationType),
        style: TextStyle(fontSize: 20 * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(-80 * scale, -iconPainter.height / 2));

    // Name
    final namePainter = TextPainter(
      text: TextSpan(
        text: WaveFormation.getFormationName(formationType),
        style: TextStyle(
          color: const Color(0xFFCE93D8).withAlpha(alpha),
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    namePainter.layout();
    namePainter.paint(canvas, Offset(-namePainter.width / 2 + 20, -namePainter.height / 2));

    canvas.restore();
  }
}