import 'package:hive_flutter/hive_flutter.dart';
import 'settings_service.dart';

class GameStateService {
  static const String _boxName = 'gameState';
  static const String _highScoreKey = 'highScore';
  
  late Box _box;
  bool _initialized = false;
  late SettingsService _settings;
  SettingsService get settings => _settings;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _settings = SettingsService();
    await _settings.init();
    _initialized = true;
  }

  int getHighScore() {
    return _box.get(_highScoreKey, defaultValue: 0) as int;
  }

  Future<void> saveHighScore(int score) async {
    final current = getHighScore();
    if (score > current) {
      await _box.put(_highScoreKey, score);
      _settings.highScore = score;
    }
  }

  void incrementGamesPlayed() {
    _settings.incrementGamesPlayed();
  }

  void addToTotalScore(int score) {
    _settings.addToTotalScore(score);
  }

  int get gamesPlayed => _settings.gamesPlayed;
  int get totalScore => _settings.totalScore;
}