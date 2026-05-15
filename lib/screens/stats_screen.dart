import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _totalGames = 0;
  int _totalScore = 0;
  int _totalEnemies = 0;
  int _totalWaves = 0;
  int _highestWave = 0;
  int _highestScore = 0;
  int _totalPowerUps = 0;
  int _totalBossesDefeated = 0;
  int _totalPlayTime = 0; // in seconds
  int _perfectWaves = 0;
  int _maxCombo = 0;
  String _playTimeFormatted = '0h 0m';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalGames = prefs.getInt('stat_games_played') ?? 0;
      _totalScore = prefs.getInt('stat_total_score') ?? 0;
      _totalEnemies = prefs.getInt('stat_total_enemies') ?? 0;
      _totalWaves = prefs.getInt('stat_total_waves') ?? 0;
      _highestWave = prefs.getInt('stat_highest_wave') ?? 0;
      _highestScore = prefs.getInt('stat_highest_score') ?? 0;
      _totalPowerUps = prefs.getInt('stat_total_powerups') ?? 0;
      _totalBossesDefeated = prefs.getInt('stat_bosses_defeated') ?? 0;
      _totalPlayTime = prefs.getInt('stat_play_time') ?? 0;
      _perfectWaves = prefs.getInt('stat_perfect_waves') ?? 0;
      _maxCombo = prefs.getInt('stat_max_combo') ?? 0;

      final hours = _totalPlayTime ~/ 3600;
      final minutes = (_totalPlayTime % 3600) ~/ 60;
      _playTimeFormatted = '${hours}h ${minutes}m';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00BCD4),
        title: const Text('📊 Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSection('🎮 Gameplay', [
            _buildStatRow('Games Played', '$_totalGames', '🎮'),
            _buildStatRow('Total Waves Survived', '$_totalWaves', '🌊'),
            _buildStatRow('Highest Wave', '$_highestWave', '👑'),
            _buildStatRow('Perfect Waves (No Damage)', '$_perfectWaves', '✨'),
          ]),
          const SizedBox(height: 16),
          _buildSection('💯 Scores', [
            _buildStatRow('Total Score', '${_formatNumber(_totalScore)}', '💯'),
            _buildStatRow('Highest Score', '${_formatNumber(_highestScore)}', '🏆'),
            _buildStatRow('Average Score', _totalGames > 0 ? '${_formatNumber(_totalScore ~/ _totalGames)}' : '0', '📈'),
          ]),
          const SizedBox(height: 16),
          _buildSection('⚔️ Combat', [
            _buildStatRow('Enemies Destroyed', '${_formatNumber(_totalEnemies)}', '💥'),
            _buildStatRow('Bosses Defeated', '$_totalBossesDefeated', '🎯'),
            _buildStatRow('Max Combo', '$_maxCombo', '🔥'),
          ]),
          const SizedBox(height: 16),
          _buildSection('⚡ Power-Ups', [
            _buildStatRow('Power-Ups Collected', '$_totalPowerUps', '📦'),
            _buildStatRow('Per Game Avg', _totalGames > 0 ? '${(_totalPowerUps / _totalGames).toStringAsFixed(1)}' : '0', '📊'),
          ]),
          const SizedBox(height: 16),
          _buildSection('⏱️ Time', [
            _buildStatRow('Total Play Time', _playTimeFormatted, '⏰'),
            _buildStatRow('Avg Per Game', _totalGames > 0 ? '${_formatTime(_totalPlayTime ~/ _totalGames)}' : '0m', '📆'),
          ]),
          const SizedBox(height: 20),
          _buildResetButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BCD4).withAlpha(60)),
      ),
      child: Column(
        children: [
          const Text('🏆 CAREER STATS 🏆', style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          )),
          const SizedBox(height: 8),
          Text('You\'ve played $_totalGames games!', style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          )),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title, style: const TextStyle(
              color: Color(0xFF00BCD4),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            )),
          ),
          ...rows,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton(
      onPressed: () => _showResetDialog(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFFFF5722),
        side: const BorderSide(color: Color(0xFFFF5722)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('🗑️ Reset All Stats', style: TextStyle(fontSize: 14)),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Reset Stats?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all your career statistics. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('stat_games_played');
              await prefs.remove('stat_total_score');
              await prefs.remove('stat_total_enemies');
              await prefs.remove('stat_total_waves');
              await prefs.remove('stat_highest_wave');
              await prefs.remove('stat_highest_score');
              await prefs.remove('stat_total_powerups');
              await prefs.remove('stat_bosses_defeated');
              await prefs.remove('stat_play_time');
              await prefs.remove('stat_perfect_waves');
              await prefs.remove('stat_max_combo');
              if (mounted) {
                Navigator.pop(ctx);
                _loadStats();
              }
            },
            child: const Text('Reset', style: TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatTime(int seconds) {
    if (seconds >= 3600) return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
    return '${seconds ~/ 60}m';
  }
}