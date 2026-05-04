import 'package:hive/hive.dart';

class SettingsService {
  static const String _boxName = 'settings';
  static const String _keySound = 'soundEnabled';
  static const String _keyMusic = 'musicEnabled';
  static const String _keyDifficulty = 'difficulty';
  static const String _keyVibration = 'vibrationEnabled';
  static const String _keyHighScore = 'highScore';
  static const String _keyGamesPlayed = 'gamesPlayed';
  static const String _keyTotalScore = 'totalScore';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // Sound
  bool get isSoundEnabled => _box.get(_keySound, defaultValue: true);
  set isSoundEnabled(bool value) => _box.put(_keySound, value);

  // Music
  bool get isMusicEnabled => _box.get(_keyMusic, defaultValue: true);
  set isMusicEnabled(bool value) => _box.put(_keyMusic, value);

  // Vibration
  bool get isVibrationEnabled => _box.get(_keyVibration, defaultValue: true);
  set isVibrationEnabled(bool value) => _box.put(_keyVibration, value);

  // Difficulty: 1=easy, 2=normal, 3=hard
  int get difficulty => _box.get(_keyDifficulty, defaultValue: 2);
  set difficulty(int value) => _box.put(_keyDifficulty, value);

  // Stats
  int get highScore => _box.get(_keyHighScore, defaultValue: 0);
  set highScore(int value) => _box.put(_keyHighScore, value);

  int get gamesPlayed => _box.get(_keyGamesPlayed, defaultValue: 0);
  set gamesPlayed(int value) => _box.put(_keyGamesPlayed, value);

  int get totalScore => _box.get(_keyTotalScore, defaultValue: 0);
  set totalScore(int value) => _box.put(_keyTotalScore, value);

  void incrementGamesPlayed() {
    gamesPlayed = gamesPlayed + 1;
  }

  void addToTotalScore(int score) {
    totalScore = totalScore + score;
  }

  void resetStats() {
    highScore = 0;
    gamesPlayed = 0;
    totalScore = 0;
  }

  String get difficultyName {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 3:
        return 'Hard';
      default:
        return 'Normal';
    }
  }
}