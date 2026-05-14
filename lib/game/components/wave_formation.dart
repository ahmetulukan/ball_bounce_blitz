import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, TextStyle;
import '../ball_bounce_game.dart';

enum WaveFormation { line, v_shape, circle, zigzag, cluster }

class WaveFormations {
  static List<Vector2> getFormation(WaveFormation formation, int count, double centerX) {
    switch (formation) {
      case WaveFormation.line:
        return _lineFormation(count, centerX);
      case WaveFormation.v_shape:
        return _vShapeFormation(count, centerX);
      case WaveFormation.circle:
        return _circleFormation(count, centerX);
      case WaveFormation.zigzag:
        return _zigzagFormation(count, centerX);
      case WaveFormation.cluster:
        return _clusterFormation(count, centerX);
    }
  }

  static List<Vector2> _lineFormation(int count, double centerX) {
    final positions = <Vector2>[];
    final spacing = 300.0 / (count + 1);
    for (int i = 0; i < count; i++) {
      final x = centerX - 150 + spacing * (i + 1);
      positions.add(Vector2(x, -30));
    }
    return positions;
  }

  static List<Vector2> _vShapeFormation(int count, double centerX) {
    final positions = <Vector2>[];
    final mid = count ~/ 2;
    for (int i = 0; i < count; i++) {
      final offset = (i - mid).abs();
      final x = centerX + (i - mid) * 50;
      final y = -30 - offset * 40;
      positions.add(Vector2(x, y));
    }
    return positions;
  }

  static List<Vector2> _circleFormation(int count, double centerX) {
    final positions = <Vector2>[];
    final radius = 80.0;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi - pi / 2;
      final x = centerX + cos(angle) * radius;
      final y = -30 + sin(angle) * radius;
      positions.add(Vector2(x, y));
    }
    return positions;
  }

  static List<Vector2> _zigzagFormation(int count, double centerX) {
    final positions = <Vector2>[];
    for (int i = 0; i < count; i++) {
      final x = centerX + (i.isEven ? -1 : 1) * 60 + (i % 3) * 30;
      final y = -30 - i * 35;
      positions.add(Vector2(x, y));
    }
    return positions;
  }

  static List<Vector2> _clusterFormation(int count, double centerX) {
    final positions = <Vector2>[];
    final random = Random();
    for (int i = 0; i < count; i++) {
      final x = centerX + (random.nextDouble() - 0.5) * 120;
      final y = -30 - random.nextDouble() * 100;
      positions.add(Vector2(x, y));
    }
    return positions;
  }
}

// Wave spawner component that manages wave-based enemy spawning
class WaveSpawner extends Component {
  late BallBounceGame gameRef;
  final Random _random = Random();

  double _waveTimer = 0;
  double _waveInterval = 8.0; // New wave every 8 seconds
  int _currentWaveIndex = 0;
  bool _waveInProgress = false;

  // Formation patterns
  final List<WaveFormation> _formations = [
    WaveFormation.line,
    WaveFormation.v_shape,
    WaveFormation.circle,
    WaveFormation.zigzag,
    WaveFormation.cluster,
  ];

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused || gameRef.isGameOver) return;

    _waveTimer += dt;

    if (_waveTimer >= _waveInterval && !_waveInProgress) {
      _startWave();
    }
  }

  void _startWave() {
    _waveInProgress = true;
    _currentWaveIndex++;

    // Get the formation for this wave
    final formationIndex = (_currentWaveIndex - 1) % _formations.length;
    final formation = _formations[formationIndex];

    // Determine enemy count based on wave
    final enemyCount = _getEnemyCountForWave(gameRef.wave);

    // Get spawn positions
    final positions = WaveFormations.getFormation(formation, enemyCount, 200);

    // Spawn enemies with staggered timing
    for (int i = 0; i < positions.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (!gameRef.isGameOver) {
          _spawnEnemyAt(positions[i].x, positions[i].y);
        }
      });
    }

    // Wave duration
    Future.delayed(const Duration(seconds: 5), () {
      _waveInProgress = false;
      _waveTimer = 0;
    });
  }

  int _getEnemyCountForWave(int wave) {
    if (wave < 3) return 3;
    if (wave < 5) return 4;
    if (wave < 8) return 5;
    if (wave < 10) return 6;
    return (wave ~/ 2) + 2;
  }

  void _spawnEnemyAt(double x, double y) {
    final enemy = EnemyFactory.create(x, gameRef.wave, gameRef);
    enemy.gameRef = gameRef;
    enemy.position = Vector2(x, y);
    gameRef.add(enemy);
  }

  void reset() {
    _waveTimer = 0;
    _currentWaveIndex = 0;
    _waveInProgress = false;
  }
}

// Bonus wave announcement overlay
class WaveAnnouncementOverlay extends PositionComponent {
  final int waveNumber;
  final String message;
  double age = 0;
  static const double maxAge = 2.0;

  WaveAnnouncementOverlay({required this.waveNumber, required this.message});

  @override
  void update(double dt) {
    super.update(dt);
    age += dt;
    if (age >= maxAge) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = age / maxAge;
    final fadeIn = progress < 0.2 ? progress * 5 : 1.0;
    final fadeOut = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;
    final alpha = (fadeIn * fadeOut * 255).round().clamp(0, 255);

    final scale = 1.0 + sin(progress * pi) * 0.2;

    canvas.save();
    canvas.translate(200, 200);
    canvas.scale(scale);

    // Background glow
    final bgPaint = Paint()
      ..color = const Color(0xFF1A237E).withAlpha((alpha * 0.3).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 60, bgPaint);

    // Wave number
    final wavePainter = TextPainter(
      text: TextSpan(
        text: 'WAVE $waveNumber',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    wavePainter.layout();
    wavePainter.paint(canvas, Offset(-wavePainter.width / 2, -20));

    // Message
    final msgPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: Colors.white.withAlpha(alpha),
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    msgPainter.layout();
    msgPainter.paint(canvas, Offset(-msgPainter.width / 2, 10));

    canvas.restore();
  }
}