import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import '../../services/audio_manager.dart';
import '../../services/achievement_service.dart';
import '../../components/paddle.dart';
import '../../components/ball.dart';
import '../../components/enemy.dart';
import '../../components/score_display.dart';
import '../../components/lives_display.dart';
import '../../components/power_up_display.dart';
import '../../components/particle_effect.dart';
import '../../components/screen_shake.dart';
import '../../components/power_up.dart';
import '../../components/wave_announcement.dart';
import '../../components/combo_display.dart';
import '../../components/explosion_effect.dart';
import '../../components/starfield.dart';
import '../../components/ball_trail.dart';
import '../../components/pause_button.dart';
import '../../components/boss_enemy.dart';
import '../../components/wave_progress_bar.dart';
import '../../components/barrier.dart';
import '../../components/score_popup.dart';
import '../../components/achievement_popup.dart';

class GameScene extends Component with TapCallbacks, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late BallTrail ballTrail;
  late ScoreDisplay scoreDisplay;
  late LivesDisplay livesDisplay;
  late PowerUpDisplay powerUpDisplay;
  late ScreenShake screenShake;
  late WaveAnnouncement waveAnnouncement;
  late ComboDisplay comboDisplay;
  late Starfield starfield;
  late PauseButton pauseButton;
  late WaveProgressBar waveProgressBar;
  late AchievementService achievements;
  bool bossSpawnedThisWave = false;
  int _powerUpsCollected = 0;
  int _livesAtWaveStart = 3;

  int score = 0;
  int lives = 3;
  int wave = 1;
  int enemiesDestroyed = 0;
  int comboCount = 0;
  double comboTimer = 0;
  static const double comboTimeout = 2.5;

  double enemySpawnTimer = 0;
  double enemySpawnInterval = 1.5;
  double powerUpSpawnTimer = 0;
  final double powerUpSpawnInterval = 8.0;
  double barrierSpawnTimer = 0;
  final double barrierSpawnInterval = 12.0;
  bool shieldActive = false;
  int paddleShrinkTicks = 0;

  bool magnetActive = false;
  double magnetTimer = 0;

  final Random _rand = Random();

  @override
  Future<void> onLoad() async {
    paddle = Paddle();
    ball = Ball(paddle: paddle, onScore: onScore, onLifeLost: onLifeLost, onGameOver: onGameOver, gameScene: this);
    ballTrail = BallTrail(ball: ball);
    scoreDisplay = ScoreDisplay();
    livesDisplay = LivesDisplay(lives: lives);
    powerUpDisplay = PowerUpDisplay();
    screenShake = ScreenShake();
    waveAnnouncement = WaveAnnouncement();
    comboDisplay = ComboDisplay();
    starfield = Starfield(count: 50);
    pauseButton = PauseButton();
    waveProgressBar = WaveProgressBar(enemiesInWave: 15);
    achievements = AchievementService();
    await achievements.init();
    _livesAtWaveStart = lives;

    await add(starfield);
    await add(paddle);
    await add(ball);
    await add(ballTrail);
    await add(scoreDisplay);
    await add(livesDisplay);
    await add(powerUpDisplay);
    await add(screenShake);
    await add(waveAnnouncement);
    await add(comboDisplay);
    await add(pauseButton);
    await add(waveProgressBar);

    await add(Enemy(x: 200, y: 50, speed: 80, gameScene: this));
    waveAnnouncement.showWave(1);
  }

  void onScore(int points) {
    score += points;
    scoreDisplay.updateScore(score);
    achievements.onScoreChanged(score);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFFEB3B)));
    add(ScorePopup(position: ball.position.clone(), text: '+$points'));
    _registerHit();
  }

  void _registerHit() {
    comboCount++;
    comboTimer = comboTimeout;
    comboDisplay.onHit();
    achievements.onComboChanged(comboCount);
    if (comboCount >= 5) {
      score += 5;
      scoreDisplay.updateScore(score);
      if (comboCount == 5 || comboCount == 10 || comboCount == 15 || comboCount % 10 == 0) {
        add(ScorePopup(
          position: Vector2(ball.position.x, ball.position.y - 30),
          text: '🔥 COMBO x$comboCount',
          color: const Color(0xFFFF9800),
        ));
      }
    }
  }

  void onPartialHit() {}

  void onLifeLost() {
    if (shieldActive) {
      shieldActive = false;
      paddle.shielded = false;
      return;
    }
    lives--;
    comboCount = 0;
    comboTimer = 0;
    comboDisplay.reset();
    livesDisplay.lives = lives;
    screenShake.trigger(shakeIntensity: 8, shakeDuration: 0.4);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFE91E63)));
    add(ExplosionEffect(position: ball.position.clone(), color: const Color(0xFFE91E63), explosionScale: 1.2));
    AudioManager.playExplosion();

    if (lives <= 0) {
      onGameOver();
    } else {
      ball.reset();
    }
  }

  void onGameOver() {
    final game = findGame() as BallBounceBlitzGame?;
    game?.showGameOverScreen(score, wave, enemiesDestroyed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        comboCount = 0;
        comboDisplay.reset();
      }
    }

    if (magnetActive) {
      magnetTimer -= dt;
      if (magnetTimer <= 0) magnetActive = false;
    }

    enemySpawnTimer += dt;
    if (enemySpawnTimer >= enemySpawnInterval) {
      enemySpawnTimer = 0;
      _spawnEnemy();
    }
    powerUpSpawnTimer += dt;
    if (powerUpSpawnTimer >= powerUpSpawnInterval) {
      powerUpSpawnTimer = 0;
      _spawnPowerUp();
    }
    barrierSpawnTimer += dt;
    if (barrierSpawnTimer >= barrierSpawnInterval && wave >= 3) {
      barrierSpawnTimer = 0;
      _spawnBarrier();
    }
  }

  void _spawnEnemy() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final speed = 60 + (wave * 15).clamp(0, 150).toInt() + _rand.nextInt(40);

    EnemyType type = EnemyType.normal;
    if (wave >= 3) {
      final roll = _rand.nextInt(5);
      if (roll == 0) type = EnemyType.fast;
      else if (roll == 1) type = EnemyType.tough;
      else if (roll == 2) type = EnemyType.big;
      else if (roll == 3) type = EnemyType.shooter;
    }

    add(Enemy(x: x, y: -30, speed: speed.toDouble(), gameScene: this, type: type));
  }

  void _spawnPowerUp() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final typeIndex = _rand.nextInt(PowerUpType.values.length);
    final type = PowerUpType.values[typeIndex];
    add(PowerUp(x: x, y: -20, type: type, gameScene: this));
  }

  void _spawnBarrier() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 60 + _rand.nextDouble() * (gameSize.x - 120);
    final hits = (wave ~/ 3).clamp(1, 3);
    add(Barrier(x: x, y: -20, hits: hits));
  }

  void _checkNoDamageAchievement(int wave) {
    // No damage for this wave = lives same as when wave started
  }

  void _showAchievementPopup(Achievement ach) {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final popup = AchievementPopup(
      achievement: ach,
      position: Vector2(gameSize.x / 2, gameSize.y * 0.35),
      startY: gameSize.y * 0.35,
    );
    add(popup);
  }

  void onProjectileHit() {
    onLifeLost();
  }

  void collectPowerUp(PowerUpType type) {
    _powerUpsCollected++;
    achievements.onPowerUpCollected(_powerUpsCollected);
    AudioManager.playPowerUp();
    final labels = {
      'speed': '⚡ SPEED!',
      'shield': '🛡️ SHIELD!',
      'multi': '✖3 MULTI!',
      'shrink': '🔻 SHRINK!',
      'magnet': '🧲 MAGNET!',
      'fireball': '🔥 FIREBALL!',
      'explosive': '💣 EXPLOSIVE!',
    };
    add(ScorePopup(position: ball.position.clone(), text: labels[type.name] ?? '✨', color: const Color(0xFF00BCD4)));
    switch (type) {
      case PowerUpType.speed:
        ball.boost();
        powerUpDisplay.addPowerUp('SPEED', 5);
        break;
      case PowerUpType.shield:
        shieldActive = true;
        paddle.shielded = true;
        powerUpDisplay.addPowerUp('SHIELD', 8);
        break;
      case PowerUpType.multi:
        _spawnExtraBalls();
        powerUpDisplay.addPowerUp('MULTI', 6);
        break;
      case PowerUpType.shrink:
        paddleShrinkTicks++;
        paddle.shrink();
        powerUpDisplay.addPowerUp('SHRINK', 10);
        break;
      case PowerUpType.magnet:
        magnetActive = true;
        magnetTimer = 6;
        powerUpDisplay.addPowerUp('MAGNET', 6);
        break;
      case PowerUpType.fireball:
        ball.activateFireball();
        powerUpDisplay.addPowerUp('FIREBALL', 6);
        // Fire particles
        for (int i = 0; i < 8; i++) {
          add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFF5722)));
        }
        break;
      case PowerUpType.explosive:
        _triggerExplosiveEffect();
        powerUpDisplay.addPowerUp('EXPLOSIVE', 5);
        break;
    }
  }

  void _triggerExplosiveEffect() {
    // Destroy all enemies on screen
    final enemies = children.query<Enemy>();
    for (final enemy in enemies) {
      enemy.takeHit(this);
    }
    // Also destroy barriers
    final barriers = children.query<Barrier>();
    for (final barrier in barriers) {
      barrier.takeHit(this);
    }
    // Big explosion effect
    screenShake.trigger(shakeIntensity: 15, shakeDuration: 0.6);
    for (int i = 0; i < 15; i++) {
      add(ParticleEffect(
        position: Vector2(
          40 + _rand.nextDouble() * (findGame()?.size.x ?? 400) - 80,
          40 + _rand.nextDouble() * 200,
        ),
        color: const Color(0xFF673AB7),
      ));
    }
    add(ScorePopup(
      position: Vector2(findGame()?.size.x ?? 200, (findGame()?.size.y ?? 300) * 0.4),
      text: '💣 MASSIVE EXPLOSION!',
      color: const Color(0xFF673AB7),
    ));
    AudioManager.playExplosion();
  }

  void _spawnExtraBalls() {
    for (int i = 0; i < 2; i++) {
      final extra = Ball(
        paddle: paddle,
        onScore: (pts) { score += pts ~/ 2; scoreDisplay.updateScore(score); _registerHit(); },
        onLifeLost: () {}, // Extra balls don't cost lives when they fall
        onGameOver: () {},
        gameScene: this,
        isExtra: true,
      );
      add(extra);
    }
  }

  void onEnemyDestroyed() {
    enemiesDestroyed++;
    if (enemiesDestroyed == 1) achievements.onFirstEnemyDestroyed();
    achievements.onEnemyDestroyed(enemiesDestroyed, _powerUpsCollected);
    waveProgressBar.setProgress(enemiesDestroyed % 15, 15);
    final waveFloor = enemiesDestroyed ~/ 15;
    final newWave = waveFloor + 1;
    if (newWave > wave) {
      wave = newWave;
      _checkNoDamageAchievement(wave);
      achievements.onWaveChanged(wave);
      achievements.onWaveCleared(wave, lives, enemiesDestroyed);
      // Wave clear bonus
      final waveBonus = wave * 10;
      score += waveBonus;
      scoreDisplay.updateScore(score);
      add(ScorePopup(
        position: Vector2(findGame()?.size.x ?? 200, (findGame()?.size.y ?? 300) * 0.4),
        text: '✨ WAVE $wave CLEARED! +$waveBonus',
        color: const Color(0xFF4CAF50),
      ));
      waveAnnouncement.showWaveComplete(wave);
      bossSpawnedThisWave = false;
      _livesAtWaveStart = lives;
      enemySpawnInterval = (1.5 - wave * 0.08).clamp(0.5, 1.5);
    }

    // Boss spawns at wave 5, 10, 15...
    if (wave >= 5 && waveFloor > 0 && waveFloor % 5 == 0 && !bossSpawnedThisWave && enemiesDestroyed % 15 == 0) {
      bossSpawnedThisWave = true;
      _spawnBoss();
    }
  }

  void _spawnBoss() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = gameSize.x / 2;
    waveAnnouncement.showBoss(wave);
    add(BossEnemy(x: x, y: -50, speed: 40, gameScene: this, wave: wave));
  }

  void onBossDefeated() {
    achievements.onBossDefeated();
    // Bonus for defeating boss
    score += wave * 100;
    scoreDisplay.updateScore(score);
    add(ScorePopup(
      position: Vector2(findGame()?.size.x ?? 200, (findGame()?.size.y ?? 300) / 2),
      text: '👑 BOSS DEFEATED! +${wave * 100}',
      color: const Color(0xFFFFD700),
    ));
    for (int i = 0; i < 5; i++) {
      add(ParticleEffect(
        position: Vector2(
          40 + _rand.nextDouble() * (findGame()?.size.x ?? 400) - 80,
          40 + _rand.nextDouble() * 200,
        ),
        color: const Color(0xFFFFD700),
      ));
    }
    screenShake.trigger(shakeIntensity: 12, shakeDuration: 0.5);
  }

  void shake() => screenShake.trigger(shakeIntensity: 5, shakeDuration: 0.2);

  void triggerChainReaction(Vector2 origin, double radius) {
    final enemies = children.query<Enemy>();
    for (final enemy in enemies) {
      final dx = enemy.position.x - origin.x;
      final dy = enemy.position.y - origin.y;
      final dist = (dx * dx + dy * dy);
      if (dist < radius * radius && dist > 0) {
        enemy.hits = (enemy.hits - 1).clamp(0, 999);
        if (enemy.hits <= 0) {
          AudioManager.playScore();
          AudioManager.playExplosion();
          final pts = enemy.type == EnemyType.big ? 50 : enemy.type == EnemyType.tough ? 40 : enemy.type == EnemyType.fast ? 20 : 25;
          onScore(pts);
          onEnemyDestroyed();
          enemy.removeFromParent();
        }
      }
    }
  }
}
