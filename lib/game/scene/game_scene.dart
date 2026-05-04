import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import '../../components/ball.dart';
import '../../components/paddle.dart';
import '../../components/enemy.dart';
import '../../components/enemy_spawn_manager.dart';
import '../../components/boss_enemy.dart';
import '../../components/power_up.dart';
import '../../components/starfield.dart';
import '../../components/score_display.dart';
import '../../components/lives_display.dart';
import '../../components/combo_display.dart';
import '../../components/wave_display.dart';
import '../../components/wave_progress_bar.dart';
import '../../components/wave_announcement.dart';
import '../../components/screen_flash.dart';
import '../../components/screen_shake.dart';
import '../../components/explosion_effect.dart';
import '../../components/shockwave_effect.dart';
import '../../components/hit_spark.dart';
import '../../components/score_popup.dart';
import '../../components/achievement_popup.dart';
import '../../components/power_up_display.dart';
import '../../components/particle_effect.dart';
import '../../components/enemy_destroy_particle.dart';
import '../../services/audio_manager.dart';
import '../../services/achievement_service.dart';
import '../game.dart';

class GameScene extends Component with TapCallbacks, HasGameRef<BallBounceBlitzGame> {
  late Paddle paddle;
  late Ball ball;
  final List<Ball> _balls = [];
  final List<Enemy> _enemies = [];
  final List<BossEnemy> _bosses = [];
  final List<PowerUp> _powerUps = [];
  int score = 0;
  int lives = 3;
  int wave = 1;
  int combo = 0;
  int enemiesDestroyed = 0;
  int powerUpsCollected = 0;
  int _waveEnemiesTotal = 0;
  int _waveEnemiesDefeated = 0;
  bool _waveActive = false;
  bool _spawningWave = false;

  // Combo system
  double _comboTimer = 0.0;
  static const double comboTimeout = 3.0;

  // Difficulty scaling
  double _enemySpeedMultiplier = 1.0;
  double _enemySpawnRate = 1.0;
  int _enemiesPerWaveBase = 5;

  // Achievement tracking
  final AchievementService _achievements = AchievementService();
  bool _waveDamageTaken = false;

  // Visual components
  late ComboDisplay comboDisplay;
  late WaveDisplay waveDisplay;
  late WaveProgressBar waveProgressBar;
  late LivesDisplay livesDisplay;
  late ScoreDisplay scoreDisplay;
  late PowerUpDisplay powerUpDisplay;
  late Starfield starfield;

  @override
  Future<void> onLoad() async {
    await _achievements.init();

    starfield = Starfield();
    add(starfield);

    paddle = Paddle();
    add(paddle);

    ball = Ball(paddle: paddle, onEnemyHit: _onBallHitEnemy, onLoseBall: _onBallLost);
    add(ball);
    _balls.add(ball);

    waveDisplay = WaveDisplay(wave);
    add(waveDisplay);

    comboDisplay = ComboDisplay();
    add(comboDisplay);

    waveProgressBar = WaveProgressBar();
    add(waveProgressBar);

    livesDisplay = LivesDisplay(lives);
    add(livesDisplay);

    scoreDisplay = ScoreDisplay(score);
    add(scoreDisplay);

    powerUpDisplay = PowerUpDisplay(powerUpsCollected);
    add(powerUpDisplay);

    add(AchievementPopup());

    _startWave(1);
    _achievements.onWaveStarted(wave, lives, enemiesDestroyed);
  }

  void _startWave(int w) {
    wave = w;
    _waveActive = false;
    _spawningWave = false;
    _waveEnemiesDefeated = 0;
    _waveEnemiesTotal = _calculateWaveEnemies(w);
    _waveDamageTaken = false;

    _enemySpeedMultiplier = 1.0 + (w - 1) * 0.08;
    _enemySpawnRate = 1.0 + (w - 1) * 0.12;
    _enemiesPerWaveBase = 5 + (w - 1) * 2;

    waveDisplay.updateWave(w);
    waveProgressBar.setProgress(0, _waveEnemiesTotal);
    _achievements.onWaveChanged(w);

    add(WaveAnnouncement(w, _isBossWave(w)));

    if (_isBossWave(w)) {
      _spawnBoss();
    } else {
      _spawnWaveEnemies();
    }
  }

  int _calculateWaveEnemies(int w) {
    return _enemiesPerWaveBase + (w * 3) + (w ~/ 2);
  }

  bool _isBossWave(int w) => w > 0 && w % 5 == 0;

  void _spawnWaveEnemies() async {
    _spawningWave = true;
    await Future.delayed(const Duration(seconds: 2));
    _waveActive = true;
    _spawnEnemiesLoop();
  }

  void _spawnEnemiesLoop() async {
    if (!_waveActive || !isMounted) return;

    final toSpawn = min(3, _waveEnemiesTotal - _waveEnemiesDefeated);
    for (int i = 0; i < toSpawn; i++) {
      if (!isMounted) return;
      _spawnSingleEnemy();
      await Future.delayed(Duration(milliseconds: (800 / _enemySpawnRate).round()));
    }

    while (_waveActive && _waveEnemiesDefeated < _waveEnemiesTotal && isMounted) {
      await Future.delayed(Duration(milliseconds: (600 / _enemySpawnRate).round()));
      if (!isMounted || !_waveActive) break;
      if (_waveEnemiesDefeated < _waveEnemiesTotal) {
        _spawnSingleEnemy();
      }
    }
  }

  void _spawnSingleEnemy() {
    final gameSize = gameRef.size;
    final random = Random();

    EnemyType type = EnemyType.basic;
    if (wave >= 3) {
      final roll = random.nextDouble();
      if (wave >= 7 && roll < 0.2) {
        type = EnemyType.tough;
      } else if (wave >= 5 && roll < 0.35) {
        type = EnemyType.fast;
      } else if (wave >= 4 && roll < 0.45) {
        type = EnemyType.armored;
      }
    }

    final enemy = Enemy(
      position: Vector2(
        50 + random.nextDouble() * (gameSize.x - 100),
        -40,
      ),
      type: type,
      speedMultiplier: _enemySpeedMultiplier,
    );
    add(enemy);
    _enemies.add(enemy);
  }

  void _spawnBoss() async {
    _spawningWave = true;
    await Future.delayed(const Duration(seconds: 3));
    _waveActive = true;

    final gameSize = gameRef.size;
    final boss = BossEnemy(
      position: Vector2(gameSize.x / 2, -80),
      speedMultiplier: _enemySpeedMultiplier,
      wave: wave,
    );
    add(boss);
    _bosses.add(boss);
  }

  void _onBallHitEnemy(Enemy enemy, Ball ball) {
    _destroyEnemy(enemy, fromBall: true);

    combo++;
    _comboTimer = comboTimeout;
    comboDisplay.updateCombo(combo);

    final points = _calculateScore();
    score += points;
    scoreDisplay.updateScore(score);
    _achievements.onScoreChanged(score);
    _achievements.onComboChanged(combo);

    if (enemiesDestroyed == 0) {
      _achievements.onFirstEnemyDestroyed();
    }

    if (combo >= 3) {
      add(ScorePopup(
        position: enemy.position.clone(),
        text: '+$points x$combo',
        color: combo >= 5 ? const Color(0xFFFF6B6B) : const Color(0xFFFFEB3B),
      ));
    }

    if (!_isBossWave(wave)) {
      _waveEnemiesDefeated++;
      waveProgressBar.setProgress(_waveEnemiesDefeated, _waveEnemiesTotal);
    }

    _checkWaveClear();
    AudioManager.playHit();
    _achievements.onEnemyDestroyed(enemiesDestroyed, powerUpsCollected);
  }

  int _calculateScore() {
    int base = 10;
    if (combo >= 3) base = 15;
    if (combo >= 5) base = 20;
    if (combo >= 10) base = 25;
    if (combo >= 15) base = 30;
    return base;
  }

  void _destroyEnemy(Enemy enemy, {bool fromBall = false}) {
    _enemies.remove(enemy);
    enemiesDestroyed++;

    add(ExplosionEffect(enemy.position));

    for (int i = 0; i < 5; i++) {
      add(EnemyDestroyParticle(enemy.position));
    }

    add(HitSpark(enemy.position));

    if (enemy.type == EnemyType.tough || enemy.type == EnemyType.armored) {
      add(ScreenShake(duration: 0.1, intensity: 3));
    }

    if (Random().nextDouble() < 0.15) {
      _spawnPowerUp(enemy.position);
    }

    enemy.removeFromParent();
  }

  void _destroyBoss(BossEnemy boss) {
    _bosses.remove(boss);
    enemiesDestroyed++;

    for (int i = 0; i < 8; i++) {
      add(ShockwaveEffect(boss.position + Vector2(
        (Random().nextDouble() - 0.5) * 100,
        (Random().nextDouble() - 0.5) * 100,
      )));
    }

    add(ScreenFlash(color: const Color(0xFFFF6B6B), duration: 0.5));
    add(ScreenShake(duration: 0.4, intensity: 8));

    final bonus = 100 * wave;
    score += bonus;
    scoreDisplay.updateScore(score);
    add(ScorePopup(
      position: boss.position,
      text: '+${bonus} BOSS!',
      color: const Color(0xFFFF6B6B),
    ));

    _achievements.onBossDefeated();
    AudioManager.playExplosion();

    boss.removeFromParent();
    _checkWaveClear();
  }

  void _spawnPowerUp(Vector2 position) {
    final types = PowerUpType.values;
    final type = types[Random().nextInt(types.length)];
    final powerUp = PowerUp(
      position: position,
      type: type,
      onCollected: _onPowerUpCollected,
    );
    add(powerUp);
    _powerUps.add(powerUp);
  }

  void _onPowerUpCollected(PowerUp powerUp, PowerUpType type) {
    powerUpsCollected++;
    powerUpDisplay.updatePowerUps(powerUpsCollected);
    _achievements.onPowerUpCollected(powerUpsCollected);

    switch (type) {
      case PowerUpType.expand:
        paddle.expand();
        break;
      case PowerUpType.shrink:
        for (final enemy in _enemies) {
          enemy.shrink();
        }
        break;
      case PowerUpType.multiBall:
        _spawnExtraBalls(2);
        break;
      case PowerUpType.speedUp:
        for (final b in _balls) {
          b.speedUp();
        }
        break;
      case PowerUpType.slowDown:
        for (final b in _balls) {
          b.slowDown();
        }
        break;
      case PowerUpType.magnet:
        paddle.activateMagnet();
        break;
    }

    AudioManager.playPowerUp();
    _powerUps.remove(powerUp);
  }

  void _spawnExtraBalls(int count) {
    for (int i = 0; i < count; i++) {
      final newBall = Ball(
        paddle: paddle,
        onEnemyHit: _onBallHitEnemy,
        onLoseBall: _onBallLost,
      );
      newBall.position = ball.position.clone();
      newBall.velocity = Vector2(
        (i == 0 ? 1 : -1) * (100 + Random().nextDouble() * 100),
        -200 - Random().nextDouble() * 100,
      );
      add(newBall);
      _balls.add(newBall);
    }
  }

  void _checkWaveClear() {
    if (_isBossWave(wave)) {
      if (_bosses.isEmpty && _waveActive) {
        _waveActive = false;
        _onWaveCleared();
      }
    } else {
      if (_waveEnemiesDefeated >= _waveEnemiesTotal && _enemies.isEmpty && _waveActive) {
        _waveActive = false;
        _onWaveCleared();
      }
    }
  }

  void _onWaveCleared() {
    _achievements.onWaveCleared(wave, lives, enemiesDestroyed);
    add(WaveClearEffect());
    AudioManager.playScore();

    score += 50 * wave;
    scoreDisplay.updateScore(score);

    Future.delayed(const Duration(seconds: 2), () {
      if (isMounted) {
        _startWave(wave + 1);
      }
    });
  }

  void _onBallLost() {
    lives--;
    livesDisplay.updateLives(lives);
    combo = 0;
    _comboTimer = 0;
    comboDisplay.updateCombo(0);
    _waveDamageTaken = true;

    if (lives <= 0) {
      _onGameOver();
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isMounted && lives > 0) {
          _respawnBall();
        }
      });
    }
  }

  void _respawnBall() {
    final newBall = Ball(
      paddle: paddle,
      onEnemyHit: _onBallHitEnemy,
      onLoseBall: _onBallLost,
    );
    add(newBall);
    _balls.add(newBall);
  }

  void _onGameOver() {
    for (final b in List.from(_balls)) {
      b.removeFromParent();
    }
    _balls.clear();
    for (final e in List.from(_enemies)) {
      e.removeFromParent();
    }
    _enemies.clear();
    for (final bo in List.from(_bosses)) {
      bo.removeFromParent();
    }
    _bosses.clear();

    gameRef.showGameOverScreen(score, wave, enemiesDestroyed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (combo > 0) {
      _comboTimer -= dt;
      comboDisplay.updateComboTimer(_comboTimer / comboTimeout);
      if (_comboTimer <= 0) {
        combo = 0;
        _comboTimer = 0;
        comboDisplay.updateCombo(0);
      }
    }

    // Collision: balls vs enemies
    for (final ball in List.from(_balls)) {
      for (final enemy in List.from(_enemies)) {
        if (ball.canHit && enemy.isActive && ball.toRect().overlaps(enemy.toRect())) {
          ball.onHitEnemy();
          _onBallHitEnemy(enemy, ball);
        }
      }

      for (final boss in List.from(_bosses)) {
        if (ball.canHit && boss.isActive && ball.toRect().overlaps(boss.toRect())) {
          ball.onHitEnemy();
          boss.takeDamage(1);
          add(HitSpark(ball.position));
          add(ScreenShake(duration: 0.05, intensity: 2));
          AudioManager.playHit();

          if (boss.isDefeated) {
            _destroyBoss(boss);
          }
        }
      }
    }
  }

  void onPaddleHitBall(Ball ball) {
    AudioManager.playHit();
    add(HitSpark(ball.position));
  }
}
