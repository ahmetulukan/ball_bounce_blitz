import 'dart:async';
import 'package:flutter/material.dart';
import '../ball_bounce_game.dart';
import '../components/ball.dart';
import '../systems/combo_system.dart';

class HudOverlay extends StatefulWidget {
  final BallBounceGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.game.comboSystem;
    final comboActive = combo.currentCombo >= 3;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Score + Combo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreChip(),
              if (comboActive) ...[
                const SizedBox(height: 6),
                _comboChip(combo),
              ],
            ],
          ),
          // Center: Wave
          _waveChip(),
          // Right: Lives + Power-up indicators
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _livesRow(),
              const SizedBox(height: 6),
              _powerUpIndicators(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'SCORE: ${widget.game.score}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _comboChip(ComboSystem combo) {
    final timerRatio = combo.timerRatio;
    final color = _comboColor(combo.currentCombo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${combo.comboEmoji} ✕${combo.currentCombo}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 70,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: timerRatio,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          if (combo.currentCombo >= 5)
            Text(
              '+${combo.multiplier.toStringAsFixed(1)}x pts',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Color _comboColor(int count) {
    if (count >= 15) return const Color(0xFFE91E63);
    if (count >= 10) return const Color(0xFFFF5722);
    if (count >= 5) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  Widget _waveChip() {
    final isBoss = widget.game.isBossWave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isBoss
            ? const Color(0xFFFF5722).withAlpha(200)
            : const Color(0xFF9C27B0).withAlpha(200),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBoss ? const Color(0xFFFFD700) : const Color(0xFFCE93D8),
          width: 1.5,
        ),
      ),
      child: Text(
        isBoss ? '👑 WAVE ${widget.game.wave}' : '🌊 WAVE ${widget.game.wave}',
        style: TextStyle(
          color: isBoss ? const Color(0xFFFFD700) : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _livesRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < widget.game.lives;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            Icons.favorite,
            color: isActive ? Colors.red : Colors.grey[700],
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _powerUpIndicators() {
    final indicators = <Widget>[];
    final ball = widget.game.ball;

    if (ball.isFireball) {
      indicators.add(_powerUpBadge('🔥'));
    }
    if (ball.isShielded) {
      indicators.add(_powerUpBadge('🛡️'));
    }
    if (ball.speed > Ball.baseSpeed * 1.1) {
      indicators.add(_powerUpBadge('⚡'));
    }

    if (indicators.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: indicators);
  }

  Widget _powerUpBadge(String icon) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(icon, style: const TextStyle(fontSize: 12)),
    );
  }
}
