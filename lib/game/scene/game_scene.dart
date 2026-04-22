import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game.dart';
import '../components/paddle.dart';
import '../components/ball.dart';
import '../components/enemy.dart';
import '../components/score_display.dart';
import '../components/lives_display.dart';
import '../components/power_up_display.dart';
import '../components/particle_effect.dart';
import '../components/screen_shake.dart';
import '../components/power_up.dart';
import '../components/wave_announcement.dart';
import '../components/combo_display.dart';
import '../components/explosion_effect.dart';
import '../components/starfield.dart';
import '../components/ball_trail.dart';

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

    await add(Enemy(x: 200, y: 50, speed: 80, gameScene: this));
    waveAnnouncement.showWave(1);
  }

  void onScore(int points) {
    score += points;
    scoreDisplay.updateScore(score);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFFEB3B)));
    _registerHit();
  }

  void _registerHit() {
    comboCount++;
    comboTimer = comboTimeout;
    comboDisplay.onHit();
    if (comboCount >= 5) {
      score += 5;
      scoreDisplay.updateScore(score);
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
    add(ExplosionEffect(position: ball.position.clone(), color: const Color(0xFFE91E63), scale: 1.2));

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
  }

  void _spawnEnemy() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final speed = 60 + (wave * 15).clamp(0, 150).toInt() + _rand.nextInt(40);

    EnemyType type = EnemyType.normal;
    if (wave >= 3) {
      final roll = _rand.nextInt(4);
      if (roll == 0) type = EnemyType.fast;
      else if (roll == 1) type = EnemyType.tough;
      else if (roll == 2) type = EnemyType.big;
    }

    add(Enemy(x: x, y: -30, speed: speed.toDouble(), gameScene: this, type: type));
  }

  void _spawnPowerUp() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final typeIndex = _rand.nextInt(PowerUpType.values.length);
    final type = PowerUpType.values[typeIndex];
    add(PowerUp(x: x, y: -20, type: type));
  }

  void collectPowerUp(PowerUpType type) {
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
    }
  }

  void _spawnExtraBalls() {
    for (int i = 0; i < 2; i++) {
      final extra = Ball(
        paddle: paddle,
        onScore: (pts) { score += pts ~/ 2; scoreDisplay.updateScore(score); _registerHit(); },
        onLifeLost: onLifeLost,
        onGameOver: onGameOver,
        gameScene: this,
        isExtra: true,
      );
      add(extra);
    }
  }

  void onEnemyDestroyed() {
    enemiesDestroyed++;
    final newWave = (enemiesDestroyed ~/ 15) + 1;
    if (newWave > wave) {
      wave = newWave;
      waveAnnouncement.showWave(wave);
      enemySpawnInterval = (1.5 - wave * 0.08).clamp(0.5, 1.5);
    }
  }

  void shake() => screenShake.trigger();
}
