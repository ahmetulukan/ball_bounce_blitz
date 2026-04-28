import 'package:flutter/material.dart';
import '../game/game.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  final BallBounceBlitzGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _toggleSound() {
    AudioManager.toggleMute();
    setState(() {}); // Rebuild to update toggle state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00BCD4),
        title: const Text('⚙️ SETTINGS'),
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Audio', [
            ListTile(
              leading: Text(AudioManager.muted ? '🔇' : '🔊', style: const TextStyle(fontSize: 24)),
              title: const Text('Sound Effects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              subtitle: Text(AudioManager.muted ? 'Muted' : 'On', style: TextStyle(color: Colors.white.withAlpha(100))),
              trailing: Switch(
                value: !AudioManager.muted,
                activeColor: const Color(0xFF00BCD4),
                onChanged: (_) => _toggleSound(),
              ),
              onTap: _toggleSound,
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Gameplay', [
            _InfoTile(icon: '🏆', title: 'High Score', subtitle: '${widget.game.highScore}'),
            const _InfoTile(icon: '📱', title: 'Version', subtitle: '1.2.0'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Controls', [
            const _InfoTile(icon: '🕹️', title: 'Paddle', subtitle: 'Drag left/right'),
            const _InfoTile(icon: '⚡', title: 'Critical Zone', subtitle: 'Paddle edges = 25 pts'),
            const _InfoTile(icon: '🔥', title: 'Fireball', subtitle: 'Pierce through enemies'),
            const _InfoTile(icon: '💣', title: 'Explosive', subtitle: 'Destroy all on screen'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Power-Ups', [
            const _InfoTile(icon: '⚡', title: 'SPEED', subtitle: 'Ball speed boost'),
            const _InfoTile(icon: '🛡️', title: 'SHIELD', subtitle: 'Block one hit'),
            const _InfoTile(icon: '✖3', title: 'MULTI', subtitle: 'Spawn 2 extra balls'),
            const _InfoTile(icon: '🔻', title: 'SHRINK', subtitle: 'Make paddle smaller'),
            const _InfoTile(icon: '🧲', title: 'MAGNET', subtitle: 'Attract ball to paddle'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          color: Color(0xFF00BCD4),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String icon, title, subtitle;
  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(icon, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
    );
  }
}
