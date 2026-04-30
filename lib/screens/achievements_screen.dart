import 'package:flutter/material.dart';
import '../game/game.dart';
import '../services/achievement_service.dart';

class AchievementsScreen extends StatefulWidget {
  final BallBounceBlitzGame game;
  const AchievementsScreen({super.key, required this.game});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementService _achievements = AchievementService();
  Set<Achievement> _unlocked = {};

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    await _achievements.init();
    if (mounted) setState(() => _unlocked = _achievements.unlocked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00BCD4),
        title: const Text('🏆 ACHIEVEMENTS'),
        leading: IconButton(
          icon: const Text('←', style: TextStyle(fontSize: 24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯 ', style: TextStyle(fontSize: 20)),
                Text(
                  '${_unlocked.length} / ${Achievement.values.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFEB3B),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' unlocked', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: Achievement.values.length,
              itemBuilder: (ctx, i) {
                final ach = Achievement.values[i];
                final isUnlocked = _unlocked.contains(ach);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked ? const Color(0xFF1A1A2E) : const Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked ? const Color(0xFFFFEB3B).withAlpha(80) : Colors.white10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isUnlocked ? ach.icon : '🔒',
                        style: TextStyle(
                          fontSize: 28,
                          color: isUnlocked ? null : Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach.title,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ach.description,
                              style: TextStyle(
                                color: isUnlocked ? Colors.white54 : Colors.white24,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        const Text('✅', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}