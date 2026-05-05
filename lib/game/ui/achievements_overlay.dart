import 'package:flutter/material.dart';
import '../../services/achievement_service.dart';

class AchievementsListWidget extends StatefulWidget {
  final VoidCallback onClose;
  
  const AchievementsListWidget({super.key, required this.onClose});

  @override
  State<AchievementsListWidget> createState() => _AchievementsListWidgetState();
}

class _AchievementsListWidgetState extends State<AchievementsListWidget> {
  final AchievementService _achievements = AchievementService();
  Set<Achievement> _unlocked = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _achievements.init();
    if (mounted) setState(() {
      _unlocked = _achievements.unlocked;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 60)),
      ),
      margin: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ACHIEVEMENTS',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white54, size: 24),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          
          // Progress bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎯 ${_unlocked.length} / ${Achievement.values.length}',
                  style: const TextStyle(
                    color: Color(0xFFFFEB3B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Achievement list
          if (!_loaded)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: Achievement.values.length,
                itemBuilder: (ctx, i) {
                  final ach = Achievement.values[i];
                  final isUnlocked = _unlocked.contains(ach);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked 
                          ? const Color(0xFF2A2A4E)
                          : const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked 
                            ? const Color(0xFFFFD700).withValues(alpha: 50)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isUnlocked ? ach.icon : '🔒',
                          style: TextStyle(
                            fontSize: 22,
                            color: isUnlocked ? null : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ach.title,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ach.description,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white54 : Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUnlocked)
                          const Text('✅', style: TextStyle(fontSize: 18)),
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