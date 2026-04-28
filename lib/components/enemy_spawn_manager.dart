import 'dart:math';
import 'package:flame/components.dart';
import '../game/game.dart';
import 'enemy.dart';

/// Manages enemy wave spawning with progressive difficulty
class EnemySpawnManager extends Component with HasGameReference<BallBounceBlitzGame> {
  final Random _rand = Random();
  double _spawnTimer = 0;
  int _waveEnemyCount = 0;
  int _totalSpawned = 0;
  double _spawnInterval = 1.5;
  bool _waveInProgress = false;
  int _currentWave = 1;
  
  // Wave configuration
  int get enemiesPerWave => 15 + (_currentWave - 1) * 2;
  double get spawnInterval => (_spawnInterval - _currentWave * 0.05).clamp(0.5, 1.5);
  
  // Difficulty multipliers
  double get speedMultiplier => 1.0 + (_currentWave - 1) * 0.15;
  double get spawnRateMultiplier => 1.0 + (_currentWave - 1) * 0.08;
  
  void startWave(int wave, dynamic gameScene) {
    _currentWave = wave;
    _waveEnemyCount = enemiesPerWave;
    _totalSpawned = 0;
    _spawnTimer = 0.3; // Small initial delay
    _spawnInterval = spawnInterval;
    _waveInProgress = true;
  }

  void updateSpawning(double dt, dynamic gameScene) {
    if (!_waveInProgress) return;
    
    _spawnTimer += dt * spawnRateMultiplier;
    if (_spawnTimer >= _spawnInterval && _totalSpawned < _waveEnemyCount) {
      _spawnTimer = 0;
      _spawnEnemy(gameScene);
      _totalSpawned++;
    }
    
    // Check wave completion
    if (_totalSpawned >= _waveEnemyCount && _isWaveClear(gameScene)) {
      _waveInProgress = false;
    }
  }

  void _spawnEnemy(dynamic gameScene) {
    if (gameScene == null) return;
    final gameSize = game.size;
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final baseSpeed = 60 + (_currentWave * 15).clamp(0, 150);
    final speed = (baseSpeed * speedMultiplier + _rand.nextInt(40)).toDouble();

    EnemyType type = EnemyType.normal;
    if (_currentWave >= 3) {
      final roll = _rand.nextInt(4);
      if (roll == 0) type = EnemyType.fast;
      else if (roll == 1) type = EnemyType.tough;
      else if (roll == 2) type = EnemyType.big;
    }

    gameScene.add(Enemy(x: x, y: -30, speed: speed, gameScene: gameScene, type: type));
  }

  bool _isWaveClear(dynamic gameScene) {
    if (gameScene == null) return true;
    final enemies = gameScene.children.query<Enemy>();
    return enemies.isEmpty;
  }

  void pause() => _waveInProgress = false;
  void resume(dynamic gameScene) {
    if (_totalSpawned < _waveEnemyCount) {
      _waveInProgress = true;
    }
  }

  int get wave => _currentWave;
  bool get isWaveInProgress => _waveInProgress;
  double get progress => _waveEnemyCount > 0 ? _totalSpawned / _waveEnemyCount : 0;
}