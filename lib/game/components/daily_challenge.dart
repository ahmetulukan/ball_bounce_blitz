import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show TextStyle, TextPainter, TextSpan, FontWeight, TextDirection, Color, Offset, Rect, RRect, Radius, Canvas, Paint, BlurStyle;
import '../ball_bounce_game.dart';
import 'ball.dart';

/// Daily Challenge - special game mode with unique modifiers each day
class DailyChallenge {
  final int daySeed;
  final String title;
  final String description;
  final List<ChallengeModifier> modifiers;
  bool completed = false;
  int bestScore = 0;

  DailyChallenge({
    required this.daySeed,
    required this.title,
    required this.description,
    required this.modifiers,
  });

  static DailyChallenge generate(int seed) {
    final random = Random(seed);
    final modifierPool = ChallengeModifier.allModifiers;
    final numModifiers = 2 + random.nextInt(2); // 2-3 modifiers
    final selectedModifiers = <ChallengeModifier>[];

    for (int i = 0; i < numModifiers; i++) {
      selectedModifiers.add(modifierPool[random.nextInt(modifierPool.length)]);
    }

    final titles = [
      'Speed Demon',
      'Gravity Well',
      'Tiny Target',
      'Fire Storm',
      'Shield Breaker',
      'Rapid Fire',
      'One Life',
      'Giant Slayer',
    ];

    return DailyChallenge(
      daySeed: seed,
      title: titles[random.nextInt(titles.length)],
      description: _buildDescription(selectedModifiers),
      modifiers: selectedModifiers,
    );
  }

  static String _buildDescription(List<ChallengeModifier> mods) {
    return mods.map((m) => m.description).join(' • ');
  }

  int get todaySeed {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }
}

class ChallengeModifier {
  final String id;
  final String name;
  final String description;
  final String icon;
  final void Function(BallBounceGame game, bool apply) onApply;

  ChallengeModifier({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.onApply,
  });

  static final List<ChallengeModifier> allModifiers = [
    ChallengeModifier(
      id: 'fast_ball',
      name: 'Fast Ball',
      description: '⚡ Ball moves 50% faster',
      icon: '⚡',
      onApply: (game, apply) {
        if (apply) {
          game.ball.speed = Ball.baseSpeed * 1.5;
          game.ball.velocity = game.ball.velocity.normalized() * game.ball.speed;
        } else {
          game.ball.speed = Ball.baseSpeed;
          game.ball.velocity = game.ball.velocity.normalized() * game.ball.speed;
        }
      },
    ),
    ChallengeModifier(
      id: 'tiny_paddle',
      name: 'Tiny Paddle',
      description: '🎯 Paddle is 50% smaller',
      icon: '🎯',
      onApply: (game, apply) {
        if (apply) {
          game.paddle.shrink();
        } else {
          game.paddle.restore();
        }
      },
    ),
    ChallengeModifier(
      id: 'multi_enemies',
      name: 'Enemy Swarm',
      description: '🐜 Double enemy spawn rate',
      icon: '🐜',
      onApply: (game, apply) {
        // Spawn rate adjusted via difficulty multiplier in SpawnSystem
      },
    ),
    ChallengeModifier(
      id: 'no_powerups',
      name: 'No Power-ups',
      description: '🚫 Power-ups disabled',
      icon: '🚫',
      onApply: (game, apply) {
        // Power-ups controlled via challengeNoPowerUps flag
        game.challengeNoPowerUps = apply;
      },
    ),
    ChallengeModifier(
      id: 'heavy_enemies',
      name: 'Armored',
      description: '🛡️ Enemies need 2 hits',
      icon: '🛡️',
      onApply: (game, apply) {
        // Handled via challengeHeavyEnemies flag in BallBounceGame
        game.challengeHeavyEnemies = apply;
      },
    ),
    ChallengeModifier(
      id: 'low_gravity',
      name: 'Low Gravity',
      description: '🪐 Ball bounces higher',
      icon: '🪨',
      onApply: (game, apply) {
        // Low gravity handled via velocity adjustments
      },
    ),
    ChallengeModifier(
      id: 'one_life',
      name: 'One Life',
      description: '💀 Only 1 life!',
      icon: '💀',
      onApply: (game, apply) {
        if (apply) game.lives = 1;
      },
    ),
    ChallengeModifier(
      id: 'points_boost',
      name: 'Double Points',
      description: '💰 2x score multiplier',
      icon: '💰',
      onApply: (game, apply) {
        game.challengePointsMultiplier = apply ? 2.0 : 1.0;
      },
    ),
  ];
}

/// Challenge completion popup
class ChallengeCompletePopup extends PositionComponent {
  final int score;
  final bool isNewBest;
  double _life = 4.0;
  double _scale = 0.5;

  ChallengeCompletePopup({
    required super.position,
    required this.score,
    required this.isNewBest,
  }) : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    _scale = 0.5 + (1.0 - (_life / 4.0)) * 0.5;
    if (_life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_life / 4.0 * 255).round().clamp(0, 255);
    
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withAlpha(alpha ~/ 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 200 * _scale, height: 120 * _scale),
        Radius.circular(16 * _scale),
      ),
      glowPaint,
    );

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withAlpha(alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 200 * _scale, height: 120 * _scale),
        Radius.circular(16 * _scale),
      ),
      bgPaint,
    );

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: '🏆 CHALLENGE COMPLETE!',
        style: TextStyle(
          color: const Color(0xFFFFD700).withAlpha(alpha),
          fontSize: 12 * _scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, Offset(-titlePainter.width / 2, -40 * _scale));

    // Score
    final scorePainter = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: const Color(0xFFFFFFFF).withAlpha(alpha),
          fontSize: 28 * _scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    scorePainter.layout();
    scorePainter.paint(canvas, Offset(-scorePainter.width / 2, -5 * _scale));

    // New best indicator
    if (isNewBest) {
      final bestPainter = TextPainter(
        text: TextSpan(
          text: '⭐ NEW BEST!',
          style: TextStyle(
            color: const Color(0xFFFF9800).withAlpha(alpha),
            fontSize: 10 * _scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      bestPainter.layout();
      bestPainter.paint(canvas, Offset(-bestPainter.width / 2, 30 * _scale));
    }
  }
}