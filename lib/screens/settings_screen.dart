import 'package:flutter/material.dart';
import '../game/game.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatelessWidget {
  final BallBounceBlitzGame game;
  const SettingsScreen({super.key, required this.game});

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
            _SoundToggleTile(
              icon: AudioManager.muted ? '🔇' : '🔊',
              title: 'Sound Effects',
              subtitle: AudioManager.muted ? 'Muted' : 'On',
              onTap: () {
                AudioManager.toggleMute();
                // Force rebuild by popping and re-pushing
              },
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Gameplay', [
            _InfoTile(icon: '🎮', title: 'High Score', subtitle: '${game.highScore}'),
            _InfoTile(icon: '📱', title: 'Version', subtitle: '1.1.0'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Controls', [
            _InfoTile(icon: '🕹️', title: 'Paddle', subtitle: 'Drag left/right'),
            _InfoTile(icon: '⚡', title: 'Critical Zone', subtitle: 'Paddle edges = 25 pts'),
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

class _SoundToggleTile extends StatefulWidget {
  final String icon, title, subtitle;
  final VoidCallback onTap;
  const _SoundToggleTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  State<_SoundToggleTile> createState() => _SoundToggleTileState();
}

class _SoundToggleTileState extends State<_SoundToggleTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(widget.icon, style: const TextStyle(fontSize: 24)),
      title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(widget.subtitle, style: TextStyle(color: Colors.white.withAlpha(100))),
      trailing: Switch(
        value: !AudioManager.muted,
        activeColor: const Color(0xFF00BCD4),
        onChanged: (_) => widget.onTap(),
      ),
      onTap: widget.onTap,
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
      trailing: Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 14)),
    );
  }
}