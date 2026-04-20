import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'components/paddle.dart';
import 'components/ball.dart';
import 'components/enemy.dart';
import 'systems/spawn_system.dart';

class BallBounceGame extends FlameGame with PanDetector, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late SpawnSystem spawnSystem;

  int score = 0;
  int lives = 3;
  int wave = 1;
  int hitCount = 0;

  bool isGameOver = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    spawnSystem = SpawnSystem();
    spawnSystem.setGame(this);
    paddle = Paddle();
    ball = Ball(paddle: paddle, gameRef: this);

    add(paddle);
    add(ball);
    add(spawnSystem);
  }

  void resetGame() {
    score = 0;
    lives = 3;
    wave = 1;
    hitCount = 0;
    isGameOver = false;

    children.whereType<Enemy>().toList().forEach(remove);
    spawnSystem.reset();
    ball.reset();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    paddle.move(info.delta.global.x);
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (isGameOver) {
      overlays.remove('GameOver');
      resetGame();
    }
  }

  void addScore(int points) {
    score += points;
    hitCount++;
    if (hitCount >= 10) {
      wave++;
      hitCount = 0;
      spawnSystem.increaseDifficulty();
    }
  }

  void loseLife() {
    lives--;
    if (lives <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    isGameOver = true;
    overlays.add('GameOver');
  }
}