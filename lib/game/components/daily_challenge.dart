import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ball_bounce_game.dart';

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int targetScore;
  final int targetWave;
  final bool noPowerUps;
  final bool heavyEnemies;
  final bool fastMode;
  final int maxLives;
  final String rewardIcon;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetScore,
    required this.targetWave,
    this.noPowerUps = false,
    this.heavyEnemies = false,
    this.fastMode = false,
    this.maxLives = 1,
    this.rewardIcon = '🏆',
  });

  static DailyChallenge forToday() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);

    final challenges = [
      const DailyChallenge(
        id: 'marathon',
        title: 'Marathon Mode',
        description: 'Reach Wave 10 with only 1 life!',
        targetScore: 5000,
        targetWave: 10,
        maxLives: 1,
        rewardIcon: '🏃',
      ),
      const DailyChallenge(
        id: 'glass_cannon',
        title: 'Glass Cannon',
        description: 'Score 3000 pts using only fireball power-ups',
        targetScore: 3000,
        targetWave: 5,
        noPowerUps: true,
        heavyEnemies: true,
        maxLives: 2,
        rewardIcon: '💎',
      ),
      const DailyChallenge(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Survive 3 minutes with fast enemies only!',
        targetScore: 4000,
        targetWave: 7,
        fastMode: true,
        maxLives: 2,
        rewardIcon: '⚡',
      ),
      const DailyChallenge(
        id: 'precision',
        title: 'Precision Master',
        description: 'Reach Wave 5 without losing any life',
        targetScore: 2000,
        targetWave: 5,
        maxLives: 3,
        rewardIcon: '🎯',
      ),
      const DailyChallenge(
        id: 'beast_mode',
        title: 'Beast Mode',
        description: 'All enemies need 2 hits - survive Wave 8!',
        targetScore: 6000,
        targetWave: 8,
        heavyEnemies: true,
        maxLives: 3,
        rewardIcon: '🔥',
      ),
      const DailyChallenge(
        id: 'collector',
        title: 'Power Collector',
        description: 'Collect 20 power-ups and reach Wave 6',
        targetScore: 3500,
        targetWave: 6,
        maxLives: 3,
        rewardIcon: '📦',
      ),
    ];

    return challenges[random.nextInt(challenges.length)];
  }
}

class DailyChallengeManager extends Component with HasGameRef<BallBounceGame> {
  DailyChallenge? _todayChallenge;
  bool _completedToday = false;
  bool _claimedToday = false;
  static const String _prefKeyCompleted = 'daily_completed';
  static const String _prefKeyClaimed = 'daily_claimed';
  static const String _prefKeyDate = 'daily_date';
  int _powerUpsCollected = 0;

  @override
  Future<void> onLoad() async {
    await _loadStatus();
    _todayChallenge = DailyChallenge.forToday();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayDateString();
      final savedDate = prefs.getString(_prefKeyDate) ?? '';

      if (savedDate != today) {
        // New day, reset
        await prefs.setString(_prefKeyDate, today);
        await prefs.setBool(_prefKeyCompleted, false);
        await prefs.setBool(_prefKeyClaimed, false);
        _completedToday = false;
        _claimedToday = false;
      } else {
        _completedToday = prefs.getBool(_prefKeyCompleted) ?? false;
        _claimedToday = prefs.getBool(_prefKeyClaimed) ?? false;
      }
    } catch (_) {}
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  DailyChallenge? get todayChallenge => _todayChallenge;
  bool get isCompleted => _completedToday;
  bool get isClaimed => _claimedToday;

  void onPowerUpCollected() {
    _powerUpsCollected++;
  }

  void checkCompletion() {
    if (_completedToday || _todayChallenge == null) return;

    final game = gameRef;
    if (game.wave >= _todayChallenge!.targetWave &&
        game.score >= _todayChallenge!.targetScore) {
      _completedToday = true;
      _saveStatus();
    }
  }

  Future<void> claimReward() async {
    if (!_completedToday || _claimedToday) return;
    _claimedToday = true;
    await _saveStatus();

    // Give reward - extra high score bonus or cosmetic
    gameRef.score += 500; // Bonus points
  }

  Future<void> _saveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyCompleted, _completedToday);
      await prefs.setBool(_prefKeyClaimed, _claimedToday);
    } catch (_) {}
  }

  void reset() {
    _powerUpsCollected = 0;
    if (_todayChallenge != null) {
      // Apply challenge modifiers
      gameRef.challengeNoPowerUps = _todayChallenge!.noPowerUps;
      gameRef.challengeHeavyEnemies = _todayChallenge!.heavyEnemies;
    }
  }
}

/// Daily challenge button in HUD
class DailyChallengeButton extends PositionComponent {
  late BallBounceGame game;
  double _pulse = 0;

  DailyChallengeButton({required Vector2 position})
      : super(position: position, size: Vector2(44, 44), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    final challenge = gameRef.dailyChallengeManager.todayChallenge;
    if (challenge == null) return;

    final completed = gameRef.dailyChallengeManager.isCompleted;
    final claimed = gameRef.dailyChallengeManager.isClaimed;

    // Pulse effect for incomplete
    final scale = completed ? 1.0 : (1.0 + sin(_pulse) * 0.1);

    // Background
    final bgColor = completed
        ? (claimed ? const Color(0xFF4CAF50) : const Color(0xFFFF9800))
        : const Color(0xFF1a1a2e);
    final borderColor = completed
        ? Colors.white
        : const Color(0xFFFF9800);

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 40 * scale,
          height: 40 * scale,
        ),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = borderColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 40 * scale,
          height: 40 * scale,
        ),
        const Radius.circular(10),
      ),
      borderPaint,
    );

    // Icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: challenge.rewardIcon,
        style: TextStyle(fontSize: 20 * scale),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Checkmark if claimed
    if (claimed && completed) {
      final checkPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(-8, 0),
        Offset(-2, 6),
        checkPaint,
      );
      canvas.drawLine(
        Offset(-2, 6),
        Offset(8, -6),
        checkPaint,
      );
    }
  }
}

/// Challenge completion celebration
class ChallengeCompleteEffect extends PositionComponent {
  double _life = 2.0;
  double _phase = 0;

  ChallengeCompleteEffect() : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _phase += dt * 5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 2.0 * 255).round().clamp(0, 255);
    final scale = 1.0 + (1.0 - _life / 2.0) * 0.5;

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha ~/ 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset.zero, 80 * scale, glowPaint);

    // Border ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, 60 * scale, ringPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🎉 CHALLENGE\nCOMPLETE!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 18 * scale,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    // Sparkles
    for (int i = 0; i < 8; i++) {
      final angle = _phase + (i * pi / 4);
      final dist = 40 + sin(_phase * 2 + i) * 20;
      final x = cos(angle) * dist;
      final y = sin(angle) * dist;

      final sparklePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), 3, sparklePaint);
    }
  }
}