import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LeaderboardEntry {
  final String odId;
  String name;
  int score;
  int wave;
  int enemiesDestroyed;
  DateTime playedAt;
  int tournamentWins;
  int dailyStreak;

  LeaderboardEntry({
    required this.odId,
    required this.name,
    required this.score,
    required this.wave,
    required this.enemiesDestroyed,
    required this.playedAt,
    this.tournamentWins = 0,
    this.dailyStreak = 0,
  });

  Map<String, dynamic> toJson() => {
    'odId': odId,
    'name': name,
    'score': score,
    'wave': wave,
    'enemiesDestroyed': enemiesDestroyed,
    'playedAt': playedAt.toIso8601String(),
    'tournamentWins': tournamentWins,
    'dailyStreak': dailyStreak,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    odId: json['odId'] ?? 'anon',
    name: json['name'] ?? 'Player',
    score: json['score'] ?? 0,
    wave: json['wave'] ?? 1,
    enemiesDestroyed: json['enemiesDestroyed'] ?? 0,
    playedAt: DateTime.tryParse(json['playedAt'] ?? '') ?? DateTime.now(),
    tournamentWins: json['tournamentWins'] ?? 0,
    dailyStreak: json['dailyStreak'] ?? 0,
  );
}

class LeaderboardService {
  static const String _leaderboardKey = 'leaderboard_entries';
  static const String _playerIdKey = 'player_od_id';
  static const int maxEntries = 100;
  static const int displayCount = 10;

  final List<LeaderboardEntry> _entries = [];
  String _playerId = 'player_001';
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _playerId = prefs.getString(_playerIdKey) ?? _generatePlayerId(prefs);

    final jsonStr = prefs.getString(_leaderboardKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _entries.addAll(jsonList.map((e) => LeaderboardEntry.fromJson(e)));
        _entries.sort((a, b) => b.score.compareTo(a.score));
        if (_entries.length > maxEntries) {
          _entries.removeRange(maxEntries, _entries.length);
        }
      } catch (_) {}
    }

    _initialized = true;
  }

  String _generatePlayerId(SharedPreferences prefs) {
    final id = 'player_${DateTime.now().millisecondsSinceEpoch}';
    prefs.setString(_playerIdKey, id);
    return id;
  }

  String get playerId => _playerId;

  Future<void> submitScore({
    required String name,
    required int score,
    required int wave,
    required int enemiesDestroyed,
    int tournamentWins = 0,
    int dailyStreak = 0,
  }) async {
    final entry = LeaderboardEntry(
      odId: _playerId,
      name: name,
      score: score,
      wave: wave,
      enemiesDestroyed: enemiesDestroyed,
      playedAt: DateTime.now(),
      tournamentWins: tournamentWins,
      dailyStreak: dailyStreak,
    );

    // Check if player already has an entry and update if better
    final existingIdx = _entries.indexWhere((e) => e.odId == _playerId);
    if (existingIdx >= 0) {
      if (_entries[existingIdx].score < score) {
        _entries[existingIdx] = entry;
      }
    } else {
      _entries.add(entry);
    }

    _entries.sort((a, b) => b.score.compareTo(a.score));
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }

    await _saveEntries();
  }

  int get playerRank {
    final idx = _entries.indexWhere((e) => e.odId == _playerId);
    return idx >= 0 ? idx + 1 : -1;
  }

  LeaderboardEntry? get playerBest {
    try {
      return _entries.firstWhere((e) => e.odId == _playerId);
    } catch (_) {
      return null;
    }
  }

  List<LeaderboardEntry> getTopPlayers({int count = displayCount}) {
    return _entries.take(count).toList();
  }

  List<LeaderboardEntry> getAllEntries() => List.from(_entries);

  // Get entries filtered by time period
  List<LeaderboardEntry> getWeekly() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return _entries.where((e) => e.playedAt.isAfter(weekAgo)).take(displayCount).toList();
  }

  List<LeaderboardEntry> getMonthly() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return _entries.where((e) => e.playedAt.isAfter(monthAgo)).take(displayCount).toList();
  }

  // Filter by rank range for pagination
  List<LeaderboardEntry> getRange(int start, int end) {
    if (start < 0) start = 0;
    if (end > _entries.length) end = _entries.length;
    if (start >= _entries.length) return [];
    return _entries.sublist(start, end);
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_leaderboardKey, jsonStr);
  }

  Future<void> reset() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_leaderboardKey);
  }

  // Statistics
  int get totalPlayers => _entries.length;
  int get playerScore => playerBest?.score ?? 0;
  int get playerWave => playerBest?.wave ?? 0;

  double get percentileRank {
    if (_entries.isEmpty || playerRank < 0) return 0;
    return ((totalPlayers - playerRank) / totalPlayers) * 100;
  }
}