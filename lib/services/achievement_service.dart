import 'package:shared_preferences/shared_preferences.dart';

enum Achievement {
  firstBlood('First Blood', 'Destroy your first enemy', '💥'),
  wave5Survivor('Wave Survivor', 'Survive to wave 5', '🌊'),
  wave10Master('Wave Master', 'Survive to wave 10', '👑'),
  bossSlayer('Boss Slayer', 'Defeat your first boss', '🎯'),
  combo5('Combo Starter', 'Get a 5-hit combo', '🔥'),
  combo10('Combo Pro', 'Get a 10-hit combo', '🔥'),
  combo15('Combo Master', 'Get a 15-hit combo', '🔥'),
  score1000('Grand Score', 'Reach 1000 points', '💯'),
  score5000('High Roller', 'Reach 5000 points', '💰'),
  enemyHunter('Enemy Hunter', 'Destroy 50 enemies', '🎮'),
  noDamage('Flawless', 'Clear a wave without taking damage', '✨'),
  powerUpCollector('Collector', 'Collect 10 power-ups', '📦');

  final String title;
  final String description;
  final String icon;

  const Achievement(this.title, this.description, this.icon);
}

class AchievementService {
  static const String _prefPrefix = 'ach_';
  static AchievementService? _instance;
  final Set<Achievement> _unlocked = {};
  bool _initialized = false;

  final List<Achievement> _recentlyUnlocked = [];
  static const int maxRecent = 3;

  factory AchievementService() {
    _instance ??= AchievementService._();
    return _instance!;
  }

  AchievementService._();

  Set<Achievement> get unlocked => Set.from(_unlocked);
  List<Achievement> get recentlyUnlocked => List.from(_recentlyUnlocked);
  void clearRecentlyUnlocked() => _recentlyUnlocked.clear();

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final ach in Achievement.values) {
        if (prefs.getBool('$_prefPrefix${ach.name}') == true) {
          _unlocked.add(ach);
        }
      }
    } catch (_) {}
    _initialized = true;
  }

  Future<Achievement?> tryUnlock(Achievement ach) async {
    if (_unlocked.contains(ach)) return null;
    _unlocked.add(ach);
    _recentlyUnlocked.insert(0, ach);
    if (_recentlyUnlocked.length > maxRecent) _recentlyUnlocked.removeLast();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefPrefix${ach.name}', true);
    } catch (_) {}
    return ach;
  }

  int get totalCount => Achievement.values.length;
  int get unlockedCount => _unlocked.length;

  // ---------- Quick check helpers ----------
  bool _waveReached = false;
  bool _bossDefeated = false;
  int _currentWave = 1;
  int _livesAtWaveStart = 3;
  int _enemiesAtWaveStart = 0;

  void onWaveChanged(int wave) {
    _currentWave = wave;
    if (wave >= 5) tryUnlock(Achievement.wave5Survivor);
    if (wave >= 10) tryUnlock(Achievement.wave10Master);
  }

  void onWaveStarted(int wave, int lives, int enemiesDestroyed) {
    _waveReached = false;
    _livesAtWaveStart = lives;
    _enemiesAtWaveStart = enemiesDestroyed;
  }

  void onEnemyDestroyed(int totalEnemiesDestroyed, int totalPowerUpsCollected) {
    if (totalEnemiesDestroyed >= 50) tryUnlock(Achievement.enemyHunter);
    if (totalPowerUpsCollected >= 10) tryUnlock(Achievement.powerUpCollector);
  }

  void onBossDefeated() {
    _bossDefeated = true;
    tryUnlock(Achievement.bossSlayer);
  }

  void onScoreChanged(int score) {
    if (score >= 1000) tryUnlock(Achievement.score1000);
    if (score >= 5000) tryUnlock(Achievement.score5000);
  }

  void onComboChanged(int combo) {
    if (combo >= 5) tryUnlock(Achievement.combo5);
    if (combo >= 10) tryUnlock(Achievement.combo10);
    if (combo >= 15) tryUnlock(Achievement.combo15);
  }

  void onFirstEnemyDestroyed() => tryUnlock(Achievement.firstBlood);

  void onWaveCleared(int wave, int lives, int enemiesDestroyed) {
    // No damage = still had all starting lives at end of wave
    if (lives == _livesAtWaveStart) {
      tryUnlock(Achievement.noDamage);
    }
  }
}
