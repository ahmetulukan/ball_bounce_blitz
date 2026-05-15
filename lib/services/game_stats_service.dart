import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Game statistics service that tracks all gameplay metrics
/// and persists them to local storage.
class GameStatsService {
  static const String _gamesPlayedKey = 'stat_games_played';
  static const String _totalScoreKey = 'stat_total_score';
  static const String _totalEnemiesKey = 'stat_total_enemies';
  static const String _totalWavesKey = 'stat_total_waves';
  static const String _highestWaveKey = 'stat_highest_wave';
  static const String _highestScoreKey = 'stat_highest_score';
  static const String _totalPowerUpsKey = 'stat_total_powerups';
  static const String _bossesDefeatedKey = 'stat_bosses_defeated';
  static const String _playTimeKey = 'stat_play_time';
  static const String _perfectWavesKey = 'stat_perfect_waves';
  static const String _maxComboKey = 'stat_max_combo';
  static const String _currentStreakKey = 'stat_current_streak';
  static const String _lastPlayedKey = 'stat_last_played';
  static const String _longestStreakKey = 'stat_longest_streak';

  static GameStatsService? _instance;
  bool _initialized = false;
  late SharedPreferences _prefs;

  // In-memory stats for current session
  int _sessionScore = 0;
  int _sessionEnemies = 0;
  int _sessionWave = 1;
  int _sessionPowerUps = 0;
  int _sessionCombo = 0;
  int _sessionStartTime = 0;
  bool _sessionNoDamage = true;

  factory GameStatsService() {
    _instance ??= GameStatsService._();
    return _instance!;
  }

  GameStatsService._();

  // Session stats
  int get sessionScore => _sessionScore;
  int get sessionEnemies => _sessionEnemies;
  int get sessionWave => _sessionWave;
  int get sessionPowerUps => _sessionPowerUps;
  int get sessionCombo => _sessionCombo;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Start tracking a new game session
  void startSession() {
    _sessionScore = 0;
    _sessionEnemies = 0;
    _sessionWave = 1;
    _sessionPowerUps = 0;
    _sessionCombo = 0;
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _sessionNoDamage = true;
  }

  /// Update session score
  void onScore(int score) {
    _sessionScore = score;
  }

  /// Record enemy destroyed
  void onEnemyDestroyed() {
    _sessionEnemies++;
  }

  /// Record power-up collected
  void onPowerUpCollected() {
    _sessionPowerUps++;
  }

  /// Update current wave
  void onWaveChanged(int wave) {
    _sessionWave = wave;
  }

  /// Update max combo
  void onComboChanged(int combo) {
    if (combo > _sessionCombo) {
      _sessionCombo = combo;
    }
  }

  /// Record damage taken (breaks no-damage streak)
  void onDamageTaken() {
    _sessionNoDamage = false;
  }

  /// Called when a boss is defeated
  void onBossDefeated() async {
    final current = _prefs.getInt(_bossesDefeatedKey) ?? 0;
    await _prefs.setInt(_bossesDefeatedKey, current + 1);
  }

  /// Called when a wave is cleared
  void onWaveCleared(int wave) async {
    // Update total waves
    final totalWaves = _prefs.getInt(_totalWavesKey) ?? 0;
    await _prefs.setInt(_totalWavesKey, totalWaves + 1);

    // Check perfect wave
    if (_sessionNoDamage) {
      final perfectWaves = _prefs.getInt(_perfectWavesKey) ?? 0;
      await _prefs.setInt(_perfectWavesKey, perfectWaves + 1);
    }

    // Update highest wave if needed
    final highestWave = _prefs.getInt(_highestWaveKey) ?? 0;
    if (wave > highestWave) {
      await _prefs.setInt(_highestWaveKey, wave);
    }
  }

  /// End session and save all stats
  Future<void> endSession(int finalScore, int wave, int maxCombo) async {
    final now = DateTime.now();
    final sessionDuration = (now.millisecondsSinceEpoch - _sessionStartTime) ~/ 1000;

    // Games played
    final gamesPlayed = (_prefs.getInt(_gamesPlayedKey) ?? 0) + 1;
    await _prefs.setInt(_gamesPlayedKey, gamesPlayed);

    // Total score
    final totalScore = (_prefs.getInt(_totalScoreKey) ?? 0) + finalScore;
    await _prefs.setInt(_totalScoreKey, totalScore);

    // Total enemies
    final totalEnemies = (_prefs.getInt(_totalEnemiesKey) ?? 0) + _sessionEnemies;
    await _prefs.setInt(_totalEnemiesKey, totalEnemies);

    // Total power-ups
    final totalPowerUps = (_prefs.getInt(_totalPowerUpsKey) ?? 0) + _sessionPowerUps;
    await _prefs.setInt(_totalPowerUpsKey, totalPowerUps);

    // Highest score
    final highestScore = _prefs.getInt(_highestScoreKey) ?? 0;
    if (finalScore > highestScore) {
      await _prefs.setInt(_highestScoreKey, finalScore);
    }

    // Max combo
    final storedMaxCombo = _prefs.getInt(_maxComboKey) ?? 0;
    if (maxCombo > storedMaxCombo) {
      await _prefs.setInt(_maxComboKey, maxCombo);
    }

    // Play time
    final playTime = (_prefs.getInt(_playTimeKey) ?? 0) + sessionDuration;
    await _prefs.setInt(_playTimeKey, playTime);

    // Daily streak tracking
    await _updateStreak(now);

    // Last played
    await _prefs.setString(_lastPlayedKey, now.toIso8601String());
  }

  Future<void> _updateStreak(DateTime now) async {
    final lastPlayedStr = _prefs.getString(_lastPlayedKey);
    if (lastPlayedStr == null) {
      // First game ever
      await _prefs.setInt(_currentStreakKey, 1);
      await _prefs.setInt(_longestStreakKey, 1);
      return;
    }

    final lastPlayed = DateTime.tryParse(lastPlayedStr);
    if (lastPlayed == null) {
      await _prefs.setInt(_currentStreakKey, 1);
      return;
    }

    final daysSinceLast = _daysBetween(lastPlayed, now);

    if (daysSinceLast == 0) {
      // Already played today, no change
      return;
    } else if (daysSinceLast == 1) {
      // Played yesterday, increment streak
      final currentStreak = (_prefs.getInt(_currentStreakKey) ?? 0) + 1;
      await _prefs.setInt(_currentStreakKey, currentStreak);

      final longestStreak = _prefs.getInt(_longestStreakKey) ?? 0;
      if (currentStreak > longestStreak) {
        await _prefs.setInt(_longestStreakKey, currentStreak);
      }
    } else {
      // Streak broken
      await _prefs.setInt(_currentStreakKey, 1);
    }
  }

  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  // ---------- Getters for persisted stats ----------

  int get totalGamesPlayed => _prefs.getInt(_gamesPlayedKey) ?? 0;
  int get totalScore => _prefs.getInt(_totalScoreKey) ?? 0;
  int get totalEnemies => _prefs.getInt(_totalEnemiesKey) ?? 0;
  int get totalWaves => _prefs.getInt(_totalWavesKey) ?? 0;
  int get highestWave => _prefs.getInt(_highestWaveKey) ?? 0;
  int get highestScore => _prefs.getInt(_highestScoreKey) ?? 0;
  int get totalPowerUps => _prefs.getInt(_totalPowerUpsKey) ?? 0;
  int get bossesDefeated => _prefs.getInt(_bossesDefeatedKey) ?? 0;
  int get playTimeSeconds => _prefs.getInt(_playTimeKey) ?? 0;
  int get perfectWaves => _prefs.getInt(_perfectWavesKey) ?? 0;
  int get maxCombo => _prefs.getInt(_maxComboKey) ?? 0;
  int get currentStreak => _prefs.getInt(_currentStreakKey) ?? 0;
  int get longestStreak => _prefs.getInt(_longestStreakKey) ?? 0;
  String? get lastPlayed => _prefs.getString(_lastPlayedKey);

  /// Average score per game
  int get averageScore => totalGamesPlayed > 0 ? totalScore ~/ totalGamesPlayed : 0;

  /// Average enemies per game
  int get averageEnemies => totalGamesPlayed > 0 ? totalEnemies ~/ totalGamesPlayed : 0;

  /// Average play time per session in minutes
  int get averagePlayTimeMinutes => totalGamesPlayed > 0 ? (playTimeSeconds ~/ totalGamesPlayed) ~/ 60 : 0;

  /// Export stats as JSON for potential cloud sync
  Map<String, dynamic> exportStats() {
    return {
      'totalGamesPlayed': totalGamesPlayed,
      'totalScore': totalScore,
      'totalEnemies': totalEnemies,
      'totalWaves': totalWaves,
      'highestWave': highestWave,
      'highestScore': highestScore,
      'totalPowerUps': totalPowerUps,
      'bossesDefeated': bossesDefeated,
      'playTimeSeconds': playTimeSeconds,
      'perfectWaves': perfectWaves,
      'maxCombo': maxCombo,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPlayed': lastPlayed,
      'averageScore': averageScore,
      'averageEnemies': averageEnemies,
    };
  }

  /// Import stats from JSON
  Future<void> importStats(Map<String, dynamic> data) async {
    if (data['totalGamesPlayed'] != null) {
      await _prefs.setInt(_gamesPlayedKey, data['totalGamesPlayed']);
    }
    if (data['totalScore'] != null) {
      await _prefs.setInt(_totalScoreKey, data['totalScore']);
    }
    if (data['totalEnemies'] != null) {
      await _prefs.setInt(_totalEnemiesKey, data['totalEnemies']);
    }
    if (data['totalWaves'] != null) {
      await _prefs.setInt(_totalWavesKey, data['totalWaves']);
    }
    if (data['highestWave'] != null) {
      await _prefs.setInt(_highestWaveKey, data['highestWave']);
    }
    if (data['highestScore'] != null) {
      await _prefs.setInt(_highestScoreKey, data['highestScore']);
    }
    if (data['totalPowerUps'] != null) {
      await _prefs.setInt(_totalPowerUpsKey, data['totalPowerUps']);
    }
    if (data['bossesDefeated'] != null) {
      await _prefs.setInt(_bossesDefeatedKey, data['bossesDefeated']);
    }
    if (data['playTimeSeconds'] != null) {
      await _prefs.setInt(_playTimeKey, data['playTimeSeconds']);
    }
    if (data['perfectWaves'] != null) {
      await _prefs.setInt(_perfectWavesKey, data['perfectWaves']);
    }
    if (data['maxCombo'] != null) {
      await _prefs.setInt(_maxComboKey, data['maxCombo']);
    }
    if (data['currentStreak'] != null) {
      await _prefs.setInt(_currentStreakKey, data['currentStreak']);
    }
    if (data['longestStreak'] != null) {
      await _prefs.setInt(_longestStreakKey, data['longestStreak']);
    }
  }
}