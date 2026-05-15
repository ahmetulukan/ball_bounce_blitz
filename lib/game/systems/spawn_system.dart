import 'dart:math';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import '../components/enemy.dart';
import '../components/power_up.dart';
import '../components/boss_enemy.dart';
import '../components/wave_formation.dart';

class SpawnSystem extends Component {
  final Random _random = Random();
  double _spawnTimer = 0;
  double _powerUpTimer = 0;
  double _spawnInterval = 2.0;
  int _difficultyLevel = 1;
  bool _bossWave = false;
  bool _bossSpawned = false;
  bool challengeHeavyEnemies = false;
  late BallBounceGame gameRef;

  // Wave formations
  double _formationTimer = 0;
  static const double _formationInterval = 12.0;

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  double get _difficultyMultiplier {
    final diff = gameRef.gameState.settings.difficulty;
    switch (diff) {
      case 1: return 0.75;
      case 3: return 1.3;
      default: return 1.0;
    }
  }

  double get _enemySpeedMultiplier {
    final diff = gameRef.gameState.settings.difficulty;
    switch (diff) {
      case 1: return 0.8;
      case 3: return 1.25;
      default: return 1.0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_bossWave) {
      return;
    }

    _spawnTimer += dt;
    _powerUpTimer += dt;
    _formationTimer += dt;

    // Check for wave formation spawning
    if (_formationTimer >= _formationInterval) {
      _formationTimer = 0;
      _triggerWaveFormation();
    }

    if (_spawnTimer >= _spawnInterval / _difficultyMultiplier) {
      _spawnTimer = 0;
      _spawnEnemy();
    }

    if (_powerUpTimer >= 8.0) {
      _powerUpTimer = 0;
      _spawnPowerUp();
    }
  }

  /// Wave-based spawning: spawns enemies based on wave progress.
  int spawnWaveEnemies(int wave) {
    if (_bossWave) return 0;

    final baseCount = 1 + (wave ~/ 3);
    final spawnCount = baseCount.clamp(1, 4);

    for (int i = 0; i < spawnCount; i++) {
      Future.delayed(Duration(milliseconds: i * 300), () {
        if (!gameRef.isGameOver && !_bossWave) {
          _spawnEnemy();
        }
      });
    }
    return spawnCount;
  }

  void _spawnEnemy() {
    final x = 30.0 + _random.nextDouble() * 340;
    final enemy = EnemyFactory.create(x, _difficultyLevel, gameRef);
    enemy.speed *= _enemySpeedMultiplier;
    enemy.gameRef = gameRef;
    gameRef.add(enemy);
  }

  void _triggerWaveFormation() {
    // Only trigger formations after wave 3
    if (gameRef.wave < 3) return;
    
    final formationType = WaveFormation.getRandomFormation(gameRef.wave);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (gameRef.isGameOver) return;
      
      final formation = WaveFormation(
        type: formationType,
        enemyCount: 6 + (gameRef.wave ~/ 2).clamp(0, 4),
        wave: gameRef.wave,
        spawnDelay: 150,
      );
      formation.setGame(gameRef);
      
      // Show formation announcement
      gameRef.add(FormationAnnouncement(
        position: Vector2(200, 80),
        formationType: formationType,
      ));
      
      formation.startSpawning();
    });
  }

  void _spawnPowerUp() {
    if (gameRef.challengeNoPowerUps) return;
    final x = 30.0 + _random.nextDouble() * 340;
    
    final allTypes = PowerUpType.values;
    List<PowerUpType> availableTypes;
    
    if (gameRef.wave < 3) {
      availableTypes = [
        PowerUpType.fireball,
        PowerUpType.explosive,
        PowerUpType.shield,
        PowerUpType.speedUp,
        PowerUpType.extraLife,
        PowerUpType.magnet,
        PowerUpType.multiball,
      ];
    } else if (gameRef.wave < 6) {
      availableTypes = [
        PowerUpType.fireball,
        PowerUpType.explosive,
        PowerUpType.shield,
        PowerUpType.speedUp,
        PowerUpType.extraLife,
        PowerUpType.magnet,
        PowerUpType.multiball,
        PowerUpType.slowmo,
        PowerUpType.shrink,
        PowerUpType.laser,
      ];
    } else {
      availableTypes = allTypes;
    }
    
    final type = availableTypes[_random.nextInt(availableTypes.length)];
    final powerUp = PowerUp.spawn(type, x);
    powerUp.gameRef = gameRef;
    gameRef.add(powerUp);
  }

  void spawnBoss() {
    if (_bossSpawned) return;
    _bossWave = true;
    _bossSpawned = true;

    final boss = BossEnemy(
      wave: gameRef.wave,
      speed: 60 + gameRef.wave * 5,
    );
    boss.gameRef = gameRef;
    boss.position = Vector2(200, -80);
    gameRef.add(boss);
  }

  void onBossDefeated() {
    _bossWave = false;
  }

  void increaseDifficulty() {
    _difficultyLevel++;
    _spawnInterval = (_spawnInterval - 0.15).clamp(0.5, 2.0);

    if (gameRef.wave > 0 && gameRef.wave % 5 == 0) {
      _bossWave = true;
    }
  }

  void onWaveChanged(int wave) {
    _difficultyLevel = wave;
    _spawnInterval = (2.0 - (wave * 0.08)).clamp(0.5, 2.0);
    _formationTimer = 0;

    if (wave > 0 && wave % 5 == 0) {
      _bossWave = true;
      _bossSpawned = false;
    } else {
      _bossWave = false;
      _bossSpawned = false;
    }
  }

  void reset() {
    _spawnTimer = 0;
    _powerUpTimer = 0;
    _spawnInterval = 2.0;
    _difficultyLevel = 1;
    _bossWave = false;
    _bossSpawned = false;
    _formationTimer = 0;
  }

  bool get isBossWave => _bossWave;
}