import 'package:flutter/material.dart';

class WaveAnnouncement extends StatefulWidget {
  final int wave;
  final bool isBoss;
  final VoidCallback onComplete;

  const WaveAnnouncement({
    super.key,
    required this.wave,
    this.isBoss = false,
    required this.onComplete,
  });

  @override
  State<WaveAnnouncement> createState() => _WaveAnnouncementState();
}

class _WaveAnnouncementState extends State<WaveAnnouncement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.isBoss ? 2000 : 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isBoss ? const Color(0xFFFFD700) : const Color(0xFF00BCD4);
    final bgColor = widget.isBoss ? const Color(0xFF1A0A00) : const Color(0xFF001A1A);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withAlpha(120),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isBoss) ...[
                    const Text('👑', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 4),
                    const Text(
                      'BOSS WAVE',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'WAVE ${widget.wave}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: widget.isBoss ? 24 : 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  if (!widget.isBoss) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getWaveSubtitle(widget.wave),
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getWaveSubtitle(int wave) {
    if (wave == 1) return 'Bounce the ball, hit enemies!';
    if (wave % 5 == 0) return '⚠️ Boss Incoming!';
    if (wave < 5) return 'Speed is increasing...';
    if (wave < 10) return '🔥 Getting intense!';
    if (wave < 15) return '💀 Danger zone!';
    return '👑 You are a legend!';
  }
}
