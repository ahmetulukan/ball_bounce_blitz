import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'components/paddle.dart';
import 'components/ball.dart';
import 'components/enemy.dart';
import 'components/power_up.dart';
import 'components/particles/explosion_particle.dart';
import 'components/background_stars.dart';
import 'components/screen_shake.dart';
import 'systems/spawn_system.dart';
import 'systems/combo_system.dart';
import 'services/game_state_service.dart';

class BallBounceGame extends FlameGame with PanDetector, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late SpawnSystem spawnSystem;
  late BackgroundStars backgroundStars;
  late ComboSystem comboSystem;
  late ScreenShake screenShake;
  late GameStateService _gameState;

  int score = 0;
  int lives = 3;
  int wave = 1;
  int hitCount = 0;
  int activeEnemies = 0;
  int highScore = 0;

  bool isGameOver = false;
  bool isPaused = false;
  bool showWaveAnnouncement = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = GameStateService();
    await _gameState.init();
    highScore = _gameState.getHighScore();

    spawnSystem = SpawnSystem();
    spawnSystem.setGame(this);
    comboSystem = ComboSystem();
    comboSystem.setGame(this);
    screenShake = ScreenShake();
    backgroundStars = BackgroundStars();
    paddle = Paddle();
    ball = Ball(paddle: paddle, gameRef: this);

    add(backgroundStars);
    add(paddle);
    add(ball);
    add(spawnSystem);
    add(comboSystem);
    add(screenShake);
  }

  void playSound(String name) {
    try {
      FlameAudio.play('$name.mp3', volume: 0.5);
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
    comboSystem.reset();
    ball.reset();
    
    _showWaveAnnouncement();
  }

  void resetGame() {
    _saveHighScoreIfNeeded();
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
    comboSystem.reset();
    ball.reset();
  }

  void _showWaveAnnouncement() {
    showWaveAnnouncement = true;
    overlays.add('WaveAnnouncement');
    playSound('wave');
  }

  void onEnemyDestroyed(Enemy enemy) {
    score += enemy.points;
    hitCount++;
    activeEnemies--;
    playSound('hit');

    add(ExplosionEffect(
      position: enemy.position.clone(),
      color: Enemy.getColor(enemy.color),
      count: 8,
    ));
    screenShake.shake(intensity: 4, duration: 0.15);

    if (hitCount >= 10) {
      wave++;
      hitCount = 0;
      spawnSystem.increaseDifficulty();
      _showWaveAnnouncement();
    }
  }

  void collectPowerUp(PowerUpType type) {
    ball.applyPowerUp(type);
  }

  void triggerExplosion(Vector2 position) {
    add(ExplosionEffect(position: position.clone(), count: 20));
    screenShake.shake(intensity: 10, duration: 0.4);

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
    comboSystem.reset();
    playSound('lose');
    if (lives <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    isGameOver = true;
    _saveHighScoreIfNeeded();
    playSound('gameover');
    overlays.add('GameOver');
  }

  void _saveHighScoreIfNeeded() {
    if (score > highScore) {
      highScore = score;
      _gameState.saveHighScore(score);
    }
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;
    super.update(dt);
  }

  Vector2 get shakeOffset => screenShake.offset;
}
