import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/ball_bounce_game.dart';

class SettingsScreen extends StatefulWidget {
  final BallBounceGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _vibrationEnabled = true;
  bool _showTrailEnabled = true;
  bool _screenShakeEnabled = true;
  double _musicVolume = 0.7;
  double _sfxVolume = 0.8;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
      _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _showTrailEnabled = prefs.getBool('show_trail') ?? true;
      _screenShakeEnabled = prefs.getBool('screen_shake') ?? true;
      _musicVolume = prefs.getDouble('music_volume') ?? 0.7;
      _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
      _loaded = true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00BCD4),
        title: const Text('⚙️ Settings'),
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 24)),
          onPressed: () {
            widget.game.overlays.remove('Settings');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio Section
          _sectionTitle('🔊 Audio'),
          _switchTile('Music', 'Background music', Icons.music_note, _musicEnabled, (v) {
            setState(() => _musicEnabled = v);
            SharedPreferences.getInstance().then((p) => p.setBool('music_enabled', v));
          }),
          _sliderTile('Music Volume', _musicVolume, (v) {
            setState(() => _musicVolume = v);
            SharedPreferences.getInstance().then((p) => p.setDouble('music_volume', v));
          }),
          const SizedBox(height: 8),
          _switchTile('Sound Effects', 'Game sounds', Icons.volume_up, _sfxEnabled, (v) {
            setState(() => _sfxEnabled = v);
            SharedPreferences.getInstance().then((p) => p.setBool('sfx_enabled', v));
          }),
          _sliderTile('SFX Volume', _sfxVolume, (v) {
            setState(() => _sfxVolume = v);
            SharedPreferences.getInstance().then((p) => p.setDouble('sfx_volume', v));
          }),

          const SizedBox(height: 24),
          // Visual Section
          _sectionTitle('🎨 Visuals'),
          _switchTile('Particle Trails', 'Show ball trail effects', Icons.blur_on, _showTrailEnabled, (v) {
            setState(() => _showTrailEnabled = v);
            SharedPreferences.getInstance().then((p) => p.setBool('show_trail', v));
          }),
          _switchTile('Screen Shake', 'Shake on impacts', Icons.vibration, _screenShakeEnabled, (v) {
            setState(() => _screenShakeEnabled = v);
            SharedPreferences.getInstance().then((p) => p.setBool('screen_shake', v));
          }),
          _switchTile('Vibration', 'Haptic feedback', Icons.phone_android, _vibrationEnabled, (v) {
            setState(() => _vibrationEnabled = v);
            SharedPreferences.getInstance().then((p) => p.setBool('vibration_enabled', v));
          }),

          const SizedBox(height: 24),
          // Gameplay Section
          _sectionTitle('🎮 Gameplay'),
          _infoTile('High Score', '🏆 ${widget.game.highScore}', Icons.emoji_events),
          _infoTile('Total Games', '🎯 ${widget.game.gameState.gamesPlayed}', Icons.games),
          _infoTile('Total Score', '💰 ${widget.game.gameState.totalScore}', Icons.monetization_on),

          const SizedBox(height: 24),
          // Controls Info
          _sectionTitle('⌨️ Controls'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _controlRow('← → or A D', 'Move paddle (keyboard)'),
                SizedBox(height: 8),
                _controlRow('Mouse / Touch Drag', 'Move paddle (mouse/touch)'),
                SizedBox(height: 8),
                _controlRow('ESC', 'Pause game'),
                SizedBox(height: 8),
                _controlRow('SPACE', 'Resume game'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // About
          _sectionTitle('ℹ️ About'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '🏓 Ball Bounce Blitz',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  'Built with Flutter & Flame Engine',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00BCD4),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF5722),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile(String title, double value, Function(double) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF5722),
            inactiveColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _controlRow extends StatelessWidget {
  final String keyLabel;
  final String actionLabel;
  const _controlRow(this.keyLabel, this.actionLabel);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00BCD4).withAlpha(40),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(actionLabel, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}