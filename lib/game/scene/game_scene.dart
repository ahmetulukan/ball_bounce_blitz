import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import '../../components/paddle.dart';
import '../../components/ball.dart';
import '../../components/enemy.dart';
import '../../components/score_display.dart';
import '../../components/lives_display.dart';
import '../../components/power_up_display.dart';
import '../../components/particle_effect.dart';
import '../../components/screen_shake.dart';
import '../../components/power_up.dart';
import '../../components/combo_display.dart';
import '../../components/starfield.dart';
import '../../components/wave_announcement.dart';
import '../../components/ball_trail.dart';
import '../../components/explosion_effect.dart';
import '../../components/wave_display.dart';

class GameScene extends Component with TapCallbacks, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late BallTrail ballTrail;
  late ScoreDisplay scoreDisplay;
  late LivesDisplay livesDisplay;
  late PowerUpDisplay powerUpDisplay;
  late ScreenShake screenShake;
  late ComboDisplay comboDisplay;
  late Starfield starfield;
  late WaveAnnouncement waveAnnouncement;
  late WaveDisplay waveDisplay;
  int score = 0;
  int lives = 3;
  int highScore = 0;
  int wave = 1;
  int enemiesKilledThisWave = 0;
  int enemiesPerWave = 10;
  double enemySpawnTimer = 0;
  double enemySpawnInterval = 1.5;
  double powerUpSpawnTimer = 0;
  final double powerUpSpawnInterval = 8.0;
  bool shieldActive = false;
  int paddleShrinkTicks = 0;
  final Random _rand = Random();

  @override
  Future<void> onLoad() async {
    highScore = await gameRef.loadHighScore();

    starfield = Starfield();
    paddle = Paddle();
    ball = Ball(paddle: paddle, onScore: onScore, onLifeLost: onLifeLost, onGameOver: onGameOver, gameScene: this);
    ballTrail = BallTrail(ball: ball);
    scoreDisplay = ScoreDisplay();
    livesDisplay = LivesDisplay(lives: lives);
    powerUpDisplay = PowerUpDisplay();
    screenShake = ScreenShake();
    comboDisplay = ComboDisplay();
    waveAnnouncement = WaveAnnouncement();
    waveDisplay = WaveDisplay();

    await add(starfield);
    await add(paddle);
    await add(ballTrail);
    await add(ball);
    await add(scoreDisplay);
    await add(livesDisplay);
    await add(powerUpDisplay);
    await add(screenShake);
    await add(comboDisplay);
    await add(waveAnnouncement);
    await add(waveDisplay);

    waveAnnouncement.showWave(1);
    await add(Enemy(x: 200, y: 50, speed: 80, gameScene: this));
  }

  void onScore(int points) {
    comboDisplay.onHit();
    final multiplier = (comboDisplay.comboCount / 3).floor().clamp(1, 5);
    final finalPoints = points * multiplier;
    score += finalPoints;
    scoreDisplay.updateScore(score);
    if (score > highScore) {
      highScore = score;
      gameRef.saveHighScore(highScore);
    }
    enemiesKilledThisWave++;
    if (enemiesKilledThisWave >= enemiesPerWave) {
      _advanceWave();
    }
    waveDisplay.updateWave(wave, enemiesKilledThisWave, enemiesPerWave);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFFEB3B)));
  }

  void _advanceWave() {
    wave++;
    enemiesKilledThisWave = 0;
    enemiesPerWave = (10 + wave * 3).clamp(10, 40);
    enemySpawnInterval = (1.5 - wave * 0.08).clamp(0.5, 1.5);
    waveAnnouncement.showWave(wave);
    waveDisplay.updateWave(wave, 0, enemiesPerWave);
    add(ExplosionEffect(position: Vector2(gameRef.size.x / 2, gameRef.size.y / 2), color: const Color(0xFF00BCD4), scale: 2.0));
    screenShake.trigger(shakeIntensity: 4, shakeDuration: 0.5);
  }

  void onPartialHit() {
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFFFFFF), count: 6));
  }

  void onLifeLost() {
    if (shieldActive) {
      shieldActive = false;
      paddle.shielded = false;
      add(ExplosionEffect(position: paddle.position.clone(), color: const Color(0xFF00BCD4), scale: 1.5));
      return;
    }
    lives--;
    livesDisplay.lives = lives;
    screenShake.trigger(shakeIntensity: 12, shakeDuration: 0.5);
    add(ExplosionEffect(position: ball.position.clone(), color: const Color(0xFFE91E63), scale: 2.0));
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFE91E63)));
    comboDisplay.reset();

    if (lives <= 0) {
      onGameOver();
    } else {
      ball.reset();
    }
  }

  void onGameOver() {
    gameRef.showGameOverScreen(score, highScore);
  }

  void onEnemyDestroyed(Enemy enemy) {
    final pts = enemy.type == EnemyType.big ? 50 : enemy.type == EnemyType.tough ? 40 : enemy.type == EnemyType.fast ? 20 : 25;
    add(ExplosionEffect(position: enemy.position.clone(), color: enemy.typeColor(), scale: 1.0));
  }

  @override
  void update(double dt) {
    super.update(dt);
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
  }

  void _spawnEnemy() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final baseSpeed = 60 + (wave * 8).clamp(0, 120) + _rand.nextInt(40);
    final typeRoll = _rand.nextDouble();
    EnemyType type;
    if (typeRoll < 0.4) {
      type = EnemyType.normal;
    } else if (typeRoll < 0.62) {
      type = EnemyType.fast;
    } else if (typeRoll < 0.82) {
      type = EnemyType.tough;
    } else {
      type = EnemyType.big;
    }
    add(Enemy(x: x, y: -30, speed: baseSpeed.toDouble(), gameScene: this, type: type));
  }

  void _spawnPowerUp() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final type = PowerUpType.values[_rand.nextInt(PowerUpType.values.length)];
    add(PowerUp(x: x, y: -20, type: type));
  }

  void collectPowerUp(PowerUpType type) {
    add(ExplosionEffect(position: Vector2(paddle.position.x, paddle.position.y - 20), color: const Color(0xFFFFEB3B), scale: 1.2));
    switch (type) {
      case PowerUpType.speed:
        ball.boost();
        powerUpDisplay.addPowerUp('⚡SPEED', 5);
        break;
      case PowerUpType.shield:
        shieldActive = true;
        paddle.shielded = true;
        powerUpDisplay.addPowerUp('🛡️SHIELD', 8);
        break;
      case PowerUpType.multi:
        _spawnExtraBalls();
        powerUpDisplay.addPowerUp('✖3MULTI', 6);
        break;
      case PowerUpType.shrink:
        paddleShrinkTicks++;
        paddle.shrink();
        powerUpDisplay.addPowerUp('🔻SHRINK', 10);
        break;
    }
  }

  void _spawnExtraBalls() {
    for (int i = 0; i < 2; i++) {
      final extra = Ball(
        paddle: paddle,
        onScore: (pts) {
          comboDisplay.onHit();
          final mult = (comboDisplay.comboCount / 3).floor().clamp(1, 5);
          score += pts * mult;
          scoreDisplay.updateScore(score);
          enemiesKilledThisWave++;
          if (enemiesKilledThisWave >= enemiesPerWave) _advanceWave();
        },
        onLifeLost: onLifeLost,
        onGameOver: onGameOver,
        gameScene: this,
        isExtra: true,
      );
      add(extra);
    }
  }

  void shake() => screenShake.trigger(shakeIntensity: 5, shakeDuration: 0.3);
}
