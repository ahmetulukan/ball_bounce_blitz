import 'dart:async';
import 'dart:math';
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

class _HudOverlayState extends State<HudOverlay> with TickerProviderStateMixin {
  Timer? _timer;
  double _chargeLevel = 0;
  int _displayScore = 0;
  int _targetScore = 0;
  AnimationController? _scoreAnimController;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) setState(() {
        _chargeLevel = widget.game.chargeShot.chargeLevel;
        _targetScore = widget.game.score;
        if (_targetScore != _displayScore) {
          final diff = _targetScore - _displayScore;
          final step = (diff.abs() / 10).clamp(1, diff.abs()).round();
          _displayScore += (diff > 0 ? step : -step).clamp(-diff.abs(), diff.abs());
        }
      });
    });
    _scoreAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scoreAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.game.comboSystem;
    final comboActive = combo.currentCombo >= 3;
    final wave = widget.game.wave;
    final isBoss = widget.game.isBossWave;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Score + Combo + Wave bonus
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _scoreChip(),
              if (comboActive) ...[
                const SizedBox(height: 6),
                _comboChip(combo),
              ],
              const SizedBox(height: 4),
              _waveBonusChip(wave),
            ],
          ),
          // Center: Wave + progress
          _waveChip(),
          // Right: Lives + Power-up indicators + Charge + Enemy count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _livesRow(),
              const SizedBox(height: 6),
              _powerUpIndicators(),
              if (_chargeLevel > 0.05) ...[
                const SizedBox(height: 6),
                _chargeIndicator(),
              ],
              const SizedBox(height: 4),
              _enemyCountChip(),
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
        border: Border.all(color: const Color(0xFFFFD700).withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💰', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$_displayScore',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _waveBonusChip(int wave) {
    final bonus = 50 * wave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withAlpha(150),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '⚡ Wave clear: +$bonus',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _comboChip(ComboSystem combo) {
    final timerRatio = combo.timerRatio;
    final color = _comboColor(combo.currentCombo);
    final comboText = combo.comboEmoji;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(80), blurRadius: 8),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$comboText ✕${combo.currentCombo}',
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
    final wave = widget.game.wave;
    final hitCount = widget.game.hitCount;
    const enemiesForNextWave = 10;
    final progress = (hitCount / enemiesForNextWave).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            isBoss ? '👑 WAVE $wave' : '🌊 WAVE $wave',
            style: TextStyle(
              color: isBoss ? const Color(0xFFFFD700) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (!isBoss) ...[
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Text(
            '$hitCount/$enemiesForNextWave',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      ],
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
            isActive ? Icons.favorite : Icons.favorite_border,
            color: isActive ? Colors.red : Colors.grey[700],
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _enemyCountChip() {
    final count = widget.game.enemyManager.enemyCount;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(150),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '👾 x$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _powerUpIndicators() {
    final indicators = <Widget>[];
    final ball = widget.game.ball;

    if (ball.isFireball) indicators.add(_powerUpBadge('🔥'));
    if (ball.isShielded) indicators.add(_powerUpBadge('🛡️'));
    if (ball.hasEnergyShield) indicators.add(_powerUpBadge('🔵'));
    if (ball.isFreezeTimeActive) indicators.add(_powerUpBadge('❄️'));
    if (ball.speed > Ball.baseSpeed * 1.1) indicators.add(_powerUpBadge('⚡'));
    if (ball.hasLaser) indicators.add(_powerUpBadge('⚔️'));
    if (ball.isMagnetized) indicators.add(_powerUpBadge('🧲'));

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

  Widget _chargeIndicator() {
    final pct = _chargeLevel;
    final color = pct > 0.8
        ? const Color(0xFFE91E63)
        : pct > 0.4
            ? const Color(0xFFFF9800)
            : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pct > 0.8 ? Icons.flash_on : Icons.bolt,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 60,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(pct * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}