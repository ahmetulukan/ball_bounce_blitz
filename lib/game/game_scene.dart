import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import '../components/paddle.dart';
import '../components/ball.dart';
import '../components/enemy.dart';
import '../components/score_display.dart';
import '../components/lives_display.dart';
import '../components/power_up_display.dart';
import '../components/particle_effect.dart';
import '../components/screen_shake.dart';
import '../components/power_up.dart';

class GameScene extends Component with TapCallbacks, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late ScoreDisplay scoreDisplay;
  late LivesDisplay livesDisplay;
  late PowerUpDisplay powerUpDisplay;
  late ScreenShake screenShake;
  int score = 0;
  int lives = 3;
  double enemySpawnTimer = 0;
  final double enemySpawnInterval = 1.5;
  double powerUpSpawnTimer = 0;
  final double powerUpSpawnInterval = 8.0;
  bool shieldActive = false;
  int paddleShrinkTicks = 0;
  final Random _rand = Random();

  @override
  Future<void> onLoad() async {
    paddle = Paddle();
    ball = Ball(paddle: paddle, onScore: onScore, onLifeLost: onLifeLost, onGameOver: onGameOver, gameScene: this);
    scoreDisplay = ScoreDisplay();
    livesDisplay = LivesDisplay(lives: lives);
    powerUpDisplay = PowerUpDisplay();
    screenShake = ScreenShake();

    await add(paddle);
    await add(ball);
    await add(scoreDisplay);
    await add(livesDisplay);
    await add(powerUpDisplay);
    await add(screenShake);

    await add(Enemy(x: 200, y: 50, speed: 80, gameScene: this));
  }

  void onScore(int points) {
    score += points;
    scoreDisplay.updateScore(score);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFFFEB3B)));
  }

  void onLifeLost() {
    if (shieldActive) {
      shieldActive = false;
      paddle.shielded = false;
      return;
    }
    lives--;
    livesDisplay.lives = lives;
    screenShake.trigger(shakeIntensity: 8, shakeDuration: 0.4);
    add(ParticleEffect(position: ball.position.clone(), color: const Color(0xFFE91E63)));

    if (lives <= 0) {
      onGameOver();
    } else {
      ball.reset();
    }
  }

  void onGameOver() {
    final game = findGame() as BallBounceBlitzGame?;
    game?.showGameOverScreen(score);
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
    final speed = 60 + (score * 0.5).clamp(0, 150).toInt() + _rand.nextInt(40);
    add(Enemy(x: x, y: -30, speed: speed.toDouble(), gameScene: this));
  }

  void _spawnPowerUp() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = 40 + _rand.nextDouble() * (gameSize.x - 80);
    final type = PowerUpType.values[_rand.nextInt(PowerUpType.values.length)];
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
    }
  }

  void _spawnExtraBalls() {
    for (int i = 0; i < 2; i++) {
      final extra = Ball(
        paddle: paddle,
        onScore: (pts) { score += pts ~/ 2; scoreDisplay.updateScore(score); },
        onLifeLost: onLifeLost,
        onGameOver: onGameOver,
        gameScene: this,
        isExtra: true,
      );
      add(extra);
    }
  }

  void shake() => screenShake.trigger();
}