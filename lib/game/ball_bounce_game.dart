import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'components/paddle.dart';
import 'components/ball.dart';
import 'components/enemy.dart';
import 'components/enemy_projectile.dart';
import 'components/particles/rainbow_particle.dart' hide MagnetField;
import 'components/power_up.dart';
import 'components/particles/enhanced_particles.dart' hide MagnetField;
import 'components/particles/explosion_particle.dart';
// enhanced particles imported when needed
import 'components/background_stars.dart';
import 'components/screen_shake.dart';
import 'components/effects.dart';
import 'components/boss_enemy.dart';
import 'components/barrier.dart';
import 'components/achievement_popup.dart';
import 'components/charge_shot.dart';
import 'components/daily_challenge.dart';
import 'systems/spawn_system.dart';
import 'systems/combo_system.dart';
import 'systems/enemy_manager.dart';
import 'systems/tournament_system.dart';
import 'services/game_state_service.dart';
import '../../services/achievement_service.dart';
// achievements overlay

class BallBounceGame extends FlameGame with PanDetector, KeyboardEvents, HasCollisionDetection {
  late Paddle paddle;
  late Ball ball;
  late SpawnSystem spawnSystem;
  late BackgroundStars backgroundStars;
  late ComboSystem comboSystem;
  late ChargeShotSystem chargeShotSystem;
  late ScreenShake screenShake;
  late BarrierSpawner barrierSpawner;
  late EnemyManager enemyManager;
  late DailyChallengeManager dailyChallengeManager;
  late TournamentManager tournamentManager;
  late GameStateService _gameState;
  late AchievementService _achievements;
  GameStateService get gameState => _gameState;
  
  final List<_PendingPopup> _popupQueue = [];
  double _popupTimer = 0;

  int score = 0;
  int lives = 3;
  int wave = 1;
  int hitCount = 0;
  int activeEnemies = 0;
  int highScore = 0;
  int totalEnemiesDestroyed = 0;
  int _waveAtStart = 1;
  int _livesAtWaveStart = 3;
  bool _noDamageThisWave = false;
  bool _bossWave = false;
  double challengePointsMultiplier = 1.0;
  bool challengeNoPowerUps = false;
  bool challengeHeavyEnemies = false;

  bool isGameOver = false;
  bool isPaused = false;
  bool isSlowMo = false;
  bool isFreezeTime = false;
  double _freezeFactor = 0.25;
  double gameSpeed = 1.0;

  final Set<LogicalKeyboardKey> _keysDown = {};
  static const double _keyboardPaddleSpeed = 400;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _gameState = GameStateService();
    await _gameState.init();
    _achievements = AchievementService();
    await _achievements.init();
    highScore = _gameState.getHighScore();

    spawnSystem = SpawnSystem();
    spawnSystem.setGame(this);
    comboSystem = ComboSystem();
    comboSystem.setGame(this);
    chargeShotSystem = ChargeShotSystem();
    screenShake = ScreenShake();
    backgroundStars = BackgroundStars();
    paddle = Paddle();
    paddle.gameRef = this;
    ball = Ball(paddle: paddle, gameRef: this);

    add(backgroundStars);
    add(paddle);
    add(ball);
    add(spawnSystem);
    add(comboSystem);
    add(chargeShotSystem);
    add(screenShake);
    barrierSpawner = BarrierSpawner();
    barrierSpawner.setGame(this);
    add(barrierSpawner);
    enemyManager = EnemyManager();
    add(enemyManager);

    dailyChallengeManager = DailyChallengeManager();
    add(dailyChallengeManager);
    tournamentManager = TournamentManager();
    tournamentManager.setGame(this);
    add(tournamentManager);
  }

  @override
  void update(double dt) {
    if (isSlowMo) dt *= 0.5;
    super.update(dt);

    // Process keyboard input
    if (!isGameOver && !isPaused) {
      double dx = 0;
      if (_keysDown.contains(LogicalKeyboardKey.arrowLeft) ||
          _keysDown.contains(LogicalKeyboardKey.keyA)) {
        dx -= _keyboardPaddleSpeed * dt;
      }
      if (_keysDown.contains(LogicalKeyboardKey.arrowRight) ||
          _keysDown.contains(LogicalKeyboardKey.keyD)) {
        dx += _keyboardPaddleSpeed * dt;
      }
      if (dx != 0) paddle.move(dx);
    }

    // Process achievement popup queue
    if (_popupQueue.isNotEmpty) {
      _popupTimer += dt;
      if (_popupTimer > 0.5) {
        _popupTimer = 0;
        final p = _popupQueue.removeAt(0);
        add(AchievementPopup(
          title: p.title,
          description: p.description,
          icon: p.icon,
        ));
      }
    }
  }

  void playSound(String name) {
    try {
      FlameAudio.play('$name.mp3', volume: 0.5);
    } catch (_) {}
  }

  void triggerScreenFlash(Color color, double duration) {
    add(ScreenFlashOverlay(color: color, maxAge: duration));
  }

  void togglePause() {
    if (isGameOver || isPaused) return;
    isPaused = true;
    overlays.add('Pause');
    overlays.remove('Hud');
  }

  void resumeGame() {
    isPaused = false;
    overlays.remove('Pause');
    overlays.add('Hud');
  }

  void startGame() {
    _gameState.incrementGamesPlayed();
    score = 0;
    lives = 3;
    wave = 1;
    hitCount = 0;
    activeEnemies = 0;
    totalEnemiesDestroyed = 0;
    isGameOver = false;
    isPaused = false;
    _bossWave = false;
    _popupQueue.clear();
    _popupTimer = 0;
    _noDamageThisWave = false;

    children.whereType<Enemy>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    children.whereType<ExplosionEffect>().toList().forEach(remove);
    children.whereType<BossEnemy>().toList().forEach(remove);
    children.whereType<AchievementPopup>().toList().forEach(remove);
    children.whereType<Barrier>().toList().forEach(remove);
    barrierSpawner.reset();
    enemyManager.clearAll();
    spawnSystem.reset();
    spawnSystem.onWaveChanged(wave);
    comboSystem.reset();
    ball.reset();
    dailyChallengeManager.reset();

    overlays.add('Hud');
    _checkBossWave();
    _showWaveAnnouncement();
    _onWaveStarted();
  }

  void resetGame() {
    _saveHighScoreIfNeeded();
    score = 0;
    lives = 3;
    wave = 1;
    hitCount = 0;
    activeEnemies = 0;
    totalEnemiesDestroyed = 0;
    isGameOver = false;
    isPaused = false;
    _bossWave = false;
    _popupQueue.clear();
    _popupTimer = 0;
    _noDamageThisWave = false;

    children.whereType<Enemy>().toList().forEach(remove);
    children.whereType<PowerUp>().toList().forEach(remove);
    children.whereType<ExplosionEffect>().toList().forEach(remove);
    children.whereType<BossEnemy>().toList().forEach(remove);
    children.whereType<AchievementPopup>().toList().forEach(remove);
    children.whereType<Barrier>().toList().forEach(remove);
    barrierSpawner.reset();
    enemyManager.clearAll();
    spawnSystem.reset();
    comboSystem.reset();
    ball.reset();
    dailyChallengeManager.reset();
  }

  void _checkBossWave() {
    if (wave > 0 && wave % 5 == 0) {
      _bossWave = true;
      spawnSystem.onWaveChanged(wave);
      Future.delayed(const Duration(seconds: 2), () {
        if (!isGameOver) spawnSystem.spawnBoss();
      });
    }
  }

  void _showWaveAnnouncement() {
    overlays.add('WaveAnnouncement');
    playSound('wave');
  }

  void _onWaveStarted() {
    _waveAtStart = wave;
    _livesAtWaveStart = lives;
    _noDamageThisWave = true;
  }

  Future<void> _checkNoDamageAchievement() async {
    if (_noDamageThisWave && lives >= _livesAtWaveStart && wave > _waveAtStart) {
      final a = await _achievements.tryUnlock(Achievement.noDamage);
      if (a != null) _queueAchievement(a);
    }
    _noDamageThisWave = false;
  }

  void _queueAchievement(Achievement ach) {
    _popupQueue.add(_PendingPopup(
      title: ach.title,
      description: ach.description,
      icon: ach.icon,
    ));
  }

  Future<void> _checkAchievements() async {
    final unlocked = await _achievements.tryUnlock(Achievement.firstBlood);
    if (unlocked != null) _queueAchievement(unlocked);
    
    if (wave >= 5) {
      final a = await _achievements.tryUnlock(Achievement.wave5Survivor);
      if (a != null) _queueAchievement(a);
    }
    
    if (wave >= 10) {
      final a = await _achievements.tryUnlock(Achievement.wave10Master);
      if (a != null) _queueAchievement(a);
    }
    
    if (score >= 1000) {
      final a = await _achievements.tryUnlock(Achievement.score1000);
      if (a != null) _queueAchievement(a);
    }
    
    if (score >= 5000) {
      final a = await _achievements.tryUnlock(Achievement.score5000);
      if (a != null) _queueAchievement(a);
    }
    
    if (totalEnemiesDestroyed >= 50) {
      final a = await _achievements.tryUnlock(Achievement.enemyHunter);
      if (a != null) _queueAchievement(a);
    }
    
    final combo = comboSystem.currentCombo;
    if (combo >= 5) {
      final a = await _achievements.tryUnlock(Achievement.combo5);
      if (a != null) _queueAchievement(a);
      if (combo == 5) _showComboFlash(5);
    }
    if (combo >= 10) {
      final a = await _achievements.tryUnlock(Achievement.combo10);
      if (a != null) _queueAchievement(a);
      if (combo == 10) _showComboFlash(10);
    }
    if (combo >= 15) {
      final a = await _achievements.tryUnlock(Achievement.combo15);
      if (a != null) _queueAchievement(a);
      if (combo == 15) _showComboFlash(15);
    }
  }

  void _showComboFlash(int level) {
    add(ComboFlash(comboLevel: level));
    screenShake.shake(intensity: 2, duration: 0.1);
  }

  void _showWaveClear() {
    add(WaveClearText(position: Vector2(200, 200)));
    add(ShockwaveEffect(position: Vector2(200, 200), color: const Color(0xFF4CAF50)));

    // Wave bonus
    final bonus = 50 * wave;
    score += bonus;
    add(WaveBonusText(position: Vector2(200, 160), wave: wave));
  }

  void onEnemyDestroyed(Enemy enemy) {
    score += (enemy.points * challengePointsMultiplier).round();
    hitCount++;
    enemyManager.unregisterEnemy(enemy);
    totalEnemiesDestroyed++;
    playSound('hit');

    add(ExplosionEffect(
      position: enemy.position.clone(),
      color: Enemy.getColor(enemy.color),
      count: 8,
    ));
    screenShake.shake(intensity: 4, duration: 0.15);

    // Screen flash for big combos
    if (comboSystem.currentCombo >= 10) {
      add(ScreenFlashOverlay(color: const Color(0xFFFFFFFF), maxAge: 0.1));
    }

    // Rainbow explosion for combo milestones
    if (comboSystem.currentCombo == 10 || comboSystem.currentCombo == 20 || comboSystem.currentCombo == 30) {
      RainbowExplosion.spawn(this, enemy.position.clone(), comboSystem.currentCombo);
    }

    // Score popup
    add(FloatingScorePopup(
      position: enemy.position.clone() + Vector2(0, -20),
      text: '${enemy.points}',
      color: const Color(0xFFFFD700),
    ));

    // Combo multiplier popup
    if (comboSystem.currentCombo >= 3) {
      add(ComboMultiplierPopup(
        position: enemy.position.clone() + Vector2(0, -40),
        combo: comboSystem.currentCombo,
      ));
    }

    _checkAchievements();

    if (!_bossWave) {
      if (hitCount >= 10) {
        _checkNoDamageAchievement();
        _showWaveClear();
        wave++;
        hitCount = 0;
        spawnSystem.increaseDifficulty();
        spawnSystem.onWaveChanged(wave);
        _checkBossWave();
        _showWaveAnnouncement();
        _onWaveStarted();
        _checkAchievements();
      }
    } else {
      if (children.whereType<BossEnemy>().isEmpty) {
        _bossWave = false;
        score += 100 * wave;
        _checkNoDamageAchievement();
        _checkAchievements();
        Future.delayed(const Duration(seconds: 2), () {
          if (!isGameOver) {
            wave++;
            hitCount = 0;
            spawnSystem.increaseDifficulty();
            spawnSystem.onWaveChanged(wave);
            _checkBossWave();
            _showWaveAnnouncement();
            _onWaveStarted();
          }
        });
      }
    }
  }

  Future<void> onBossDestroyed() async {
    final a = await _achievements.tryUnlock(Achievement.bossSlayer);
    if (a != null) _queueAchievement(a);
    final bosses = children.whereType<BossEnemy>().toList();
    if (bosses.isNotEmpty) {
      enemyManager.unregisterBoss(bosses.first);
    }
  }

  Future<void> collectPowerUp(PowerUpType type) async {
    ball.applyPowerUp(type);
    final a = await _achievements.tryUnlock(Achievement.powerUpCollector);
    if (a != null) _queueAchievement(a);
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

  void startMagnetEffect() {
    ball.isMagnetized = true;
    // Add visual orbit attractor to the ball
    final attractor = MagnetAttractor(
      position: Vector2.zero(),
      orbitRadius: 30,
      orbitSpeed: 4.0,
      color: const Color(0xFFE91E63),
    );
    ball.add(attractor);
    Future.delayed(const Duration(seconds: 5), () {
      ball.isMagnetized = false;
    });
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

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _keysDown.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (!isPaused && !isGameOver) togglePause();
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (isPaused && !isGameOver) resumeGame();
      }
    } else if (event is KeyUpEvent) {
      _keysDown.remove(event.logicalKey);
    }
    return KeyEventResult.ignored;
  }

  void loseLife() {
    if (ball.isShielded) return;
    lives--;
    _noDamageThisWave = false;
    paddle.resetStreak();
    comboSystem.reset();
    playSound('lose');
    
    if (lives <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    isGameOver = true;
    overlays.remove('Hud');
    _saveHighScoreIfNeeded();
    playSound('gameover');
    overlays.add('GameOver');
  }

  void _saveHighScoreIfNeeded() {
    if (score > highScore) {
      highScore = score;
      _gameState.saveHighScore(score);
    }
    _gameState.addToTotalScore(score);
  }

  bool get isBossWave => _bossWave;

  ChargeShotSystem get chargeShot => chargeShotSystem;

  Future<int> loadHighScore() async {
    return _gameState.getHighScore();
  }

  void restart() {
    resetGame();
  }

  Vector2 get shakeOffset => screenShake.offset;

  void showAchievementsOverlay() {
    overlays.add('Achievements');
  }

  void spawnMultiball() {
    // Spawn 2 extra balls from current ball position
    for (int i = 0; i < 2; i++) {
      final extraBall = Ball(paddle: paddle, gameRef: this);
      extraBall.position = ball.position.clone();
      extraBall.speed = ball.speed;
      extraBall.isFireball = ball.isFireball;
      extraBall.isShielded = ball.isShielded;
      // Give slight angle offsets
      final angle = (i == 0 ? -0.3 : 0.3) + atan2(ball.velocity.y, ball.velocity.x);
      extraBall.velocity = Vector2(sin(angle), -cos(angle)) * extraBall.speed;
      add(extraBall);
    }
    playSound('powerup');
  }

  void startSlowMo() {
    isSlowMo = true;
    // Visual overlay effect
    add(SlowMoOverlay());
    Future.delayed(const Duration(seconds: 5), () {
      isSlowMo = false;
    });
  }

  void shrinkPaddle() {
    paddle.shrink();
    Future.delayed(const Duration(seconds: 6), () {
      paddle.restore();
    });
  }
  
  void applyFreezeEffect(double dt) {
    // Freeze time: slow down all enemies by reducing their effective speed
    // The actual slowdown happens in enemy update via this flag
    isFreezeTime = true;
  }
  
  void clearFreezeEffect() {
    isFreezeTime = false;
  }
  
  double getFreezeFactor() {
    return isFreezeTime ? _freezeFactor : 1.0;
  }
}

class _PendingPopup {
  final String title;
  final String description;
  final String icon;
  _PendingPopup({required this.title, required this.description, required this.icon});
}