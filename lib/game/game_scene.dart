import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/game.dart';
import '../components/paddle.dart';
import '../components/ball.dart';
import '../components/enemy.dart';
import '../components/score_display.dart';

class GameScene extends Component with TapCallbacks, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late ScoreDisplay scoreDisplay;
  int score = 0;
  double enemySpawnTimer = 0;
  final double enemySpawnInterval = 1.5;

  @override
  Future<void> onLoad() async {
    paddle = Paddle();
    ball = Ball(paddle: paddle, onScore: onScore, onGameOver: onGameOver);
    scoreDisplay = ScoreDisplay();

    await add(paddle);
    await add(ball);
    await add(scoreDisplay);
    await add(Enemy(x: 200, y: 50, speed: 80));
  }

  void onScore(int points) {
    score += points;
    scoreDisplay.updateScore(score);
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
  }

  void _spawnEnemy() {
    final gameSize = findGame()?.size ?? Vector2(400, 600);
    final x = (gameSize.x * 0.1) + (gameSize.x * 0.8 * (DateTime.now().millisecond % 100) / 100);
    add(Enemy(x: x, y: -30, speed: 60 + (score * 2).clamp(0, 150)));
  }
}