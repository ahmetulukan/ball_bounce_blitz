import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scene/game_scene.dart';

class BallBounceBlitzGame extends FlameGame {
  GameScene? _scene;
  bool _gameStarted = false;
  int lastScore = 0;
  int lastWave = 1;
  int lastEnemiesDestroyed = 0;
  int _highScore = 0;
  static const String _highScoreKey = 'ball_bounce_high_score';

  @override
  Future<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_gameStarted) {
      startGame();
    }
  }

  void startGame() {
    _gameStarted = true;
    _scene = GameScene();
    add(_scene!);
  }

  void showGameOverScreen(int score, int wave, int enemiesDestroyed) {
    lastScore = score;
    lastWave = wave;
    lastEnemiesDestroyed = enemiesDestroyed;
    if (score > _highScore) {
      _highScore = score;
      saveHighScore(score);
    }
    overlays.add('GameOver');
  }

  void restart() {
    overlays.remove('GameOver');
    _scene?.removeFromParent();
    _scene = null;
    _gameStarted = false;
    lastScore = 0;
    lastWave = 1;
    lastEnemiesDestroyed = 0;
    startGame();
  }

  Future<int> loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
    } catch (_) {
      _highScore = 0;
    }
    return _highScore;
  }

  Future<void> saveHighScore(int score) async {
    _highScore = score;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, score);
    } catch (_) {}
  }

  int get highScore => _highScore;
}
