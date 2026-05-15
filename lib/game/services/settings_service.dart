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
  static const String _keyStreak = 'dailyStreak';
  static const String _keyLastPlay = 'lastPlayDate';

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
    _updateStreak();
  }

  void addToTotalScore(int score) {
    totalScore = totalScore + score;
  }

  void resetStats() {
    highScore = 0;
    gamesPlayed = 0;
    totalScore = 0;
    dailyStreak = 0;
    _box.delete(_keyLastPlay);
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

  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Easy 😊';
      case 3:
        return 'Hard 😈';
      default:
        return 'Normal 😐';
    }
  }

  int get dailyStreak => _box.get(_keyStreak, defaultValue: 0);
  set dailyStreak(int value) => _box.put(_keyStreak, value);

  DateTime? get lastPlayDate {
    final ms = _box.get(_keyLastPlay) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }
  set lastPlayDate(DateTime? value) {
    if (value != null) {
      _box.put(_keyLastPlay, value.millisecondsSinceEpoch);
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPlay = lastPlayDate;

    if (lastPlay == null) {
      dailyStreak = 1;
    } else {
      final lastDay = DateTime(lastPlay.year, lastPlay.month, lastPlay.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        dailyStreak += 1;
      } else if (diff > 1) {
        dailyStreak = 1;
      }
    }
    lastPlayDate = today;
  }
}