import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'components/paddle.dart';
import 'components/ball.dart';
import 'components/enemy.dart';
import 'components/power_up.dart';
import 'components/particles/explosion_particle.dart';
import 'components/background_stars.dart';
import 'systems/spawn_system.dart';

class BallBounceGame extends FlameGame with PanDetector, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late SpawnSystem spawnSystem;
  late BackgroundStars backgroundStars;

  int score = 0;
  int lives = 3;
  int wave = 1;
  int hitCount = 0;
  int activeEnemies = 0;
  int highScore = 0;

  bool isGameOver = false;
  bool isPaused = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await FlameAudio.audioPool.init();
    spawnSystem = SpawnSystem();
    spawnSystem.setGame(this);
    backgroundStars = BackgroundStars();
    paddle = Paddle();
    ball = Ball(paddle: paddle, gameRef: this);

    add(backgroundStars);
    add(paddle);
    add(ball);
    add(spawnSystem);
  }

  void playSound(String name) {
    try {
      FlameAudio.audioPool.play('$name.mp3', volume: 0.5);
    } catch (_) {}
  }

  void togglePause() {
    if (isGameOver || isPaused) return;
    isPaused = true;
    overlays.add('Pause');
  }

  void resumeGame() {
    isPaused = false;
    overlays.remove('Pause');
  }

  void startGame() {
    score = 0;
    lives = 3;
    wave = 1;
    hitCount = 0;
    activeEnemies = 0;
    isGameOver = false;
    isPaused = false;
    children.whereType<Enemy>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    children.whereType<ExplosionEffect>().toList().forEach(remove);
    spawnSystem.reset();
    ball.reset();
  }

  void resetGame() {
    if (score > highScore) {
      highScore = score;
    }
    score = 0;
    lives = 3;
    wave = 1;
    hitCount = 0;
    activeEnemies = 0;
    isGameOver = false;
    isPaused = false;
    children.whereType<Enemy>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    children.whereType<ExplosionEffect>().toList().forEach(remove);
    spawnSystem.reset();
    ball.reset();
  }

  void onEnemyDestroyed(Enemy enemy) {
    score += enemy.points;
    hitCount++;
    activeEnemies--;
    playSound('hit');

    // Particle explosion
    add(ExplosionEffect(
      position: enemy.position.clone(),
      color: Enemy.getColor(enemy.color),
      count: 8,
    ));

    if (hitCount >= 10) {
      wave++;
      hitCount = 0;
      spawnSystem.increaseDifficulty();
      playSound('wave');
    }
  }

  void collectPowerUp(PowerUpType type) {
    ball.applyPowerUp(type);
  }

  void triggerExplosion(Vector2 position) {
    add(ExplosionEffect(position: position.clone(), count: 20));

    // Destroy nearby enemies
    final enemies = children.whereType<Enemy>().toList();
    for (final enemy in enemies) {
      if ((enemy.position - position).length < 80) {
        enemy.destroy();
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver || isPaused) return;
    paddle.move(info.delta.global.x);
  }

  @override
  void onPanDown(DragDownInfo info) {
    if (isGameOver) {
      overlays.remove('GameOver');
      resetGame();
    }
  }

  void loseLife() {
    if (ball.isShielded) return;
    lives--;
    playSound('lose');
    if (lives <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    isGameOver = true;
    if (score > highScore) {
      highScore = score;
    }
    playSound('gameover');
    overlays.add('GameOver');
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;
    super.update(dt);
  }
}