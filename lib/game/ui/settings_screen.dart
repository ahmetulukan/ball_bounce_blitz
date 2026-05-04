import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final BallBounceGame game;

  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.game.gameState.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.game.overlays.remove('Settings'),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  ),
                  const Expanded(
                    child: Text(
                      '⚙️ SETTINGS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(color: Colors.white24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sound toggle
                  _buildSettingCard(
                    icon: '🔊',
                    title: 'Sound Effects',
                    subtitle: _settings.isSoundEnabled ? 'ON' : 'OFF',
                    trailing: Switch(
                      value: _settings.isSoundEnabled,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() => _settings.isSoundEnabled = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Music toggle
                  _buildSettingCard(
                    icon: '🎵',
                    title: 'Music',
                    subtitle: _settings.isMusicEnabled ? 'ON' : 'OFF',
                    trailing: Switch(
                      value: _settings.isMusicEnabled,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() => _settings.isMusicEnabled = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Vibration toggle
                  _buildSettingCard(
                    icon: '📳',
                    title: 'Vibration',
                    subtitle: _settings.isVibrationEnabled ? 'ON' : 'OFF',
                    trailing: Switch(
                      value: _settings.isVibrationEnabled,
                      activeColor: Colors.orange,
                      onChanged: (value) {
                        setState(() => _settings.isVibrationEnabled = value);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Difficulty selector
                  _buildSettingCard(
                    icon: '🎯',
                    title: 'Difficulty',
                    subtitle: _settings.difficultyName,
                    trailing: _buildDifficultySelector(),
                  ),

                  const SizedBox(height: 24),

                  // Stats section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📊', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'STATISTICS',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('🏆 High Score', '${_settings.highScore}'),
                        _buildStatRow('🎮 Games Played', '${_settings.gamesPlayed}'),
                        _buildStatRow('📈 Total Score', '${_settings.totalScore}'),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _confirmResetStats,
                            child: const Text(
                              '🔄 Reset Statistics',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🏓 BALL BOUNCE BLITZ',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Version 1.0.0',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Built with Flutter & Flame',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDiffButton('😊', 1),
        _buildDiffButton('😐', 2),
        _buildDiffButton('😈', 3),
      ],
    );
  }

  Widget _buildDiffButton(String emoji, int level) {
    final isSelected = _settings.difficulty == level;
    return GestureDetector(
      onTap: () => setState(() => _settings.difficulty = level),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetStats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '⚠️ Reset Statistics?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will clear all your game statistics. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              _settings.resetStats();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}