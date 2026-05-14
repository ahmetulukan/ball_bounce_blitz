import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart' show TextPainter, TextSpan, TextDirection, TextStyle;
import 'package:flutter/material.dart' show Colors;
import '../ball_bounce_game.dart';
import '../components/enemy.dart';
import '../components/power_up.dart';
import '../../services/achievement_service.dart';

class ComboSystem extends Component {
  late BallBounceGame gameRef;
  int comboCount = 0;
  int maxCombo = 0;
  double comboTimer = 0;
  static const double comboTimeout = 3.0;
  
  // Tracking for achievements
  int _criticalHits = 0;
  int _chainLightningKills = 0;
  final Set<PowerUpType> _usedPowerUpTypes = {};

  void setGame(BallBounceGame game) {
    gameRef = game;
  }

  int get currentCombo => comboCount;
  double get multiplier => _calculateMultiplier();

  double get timerRatio => comboTimer > 0 ? (comboTimer / comboTimeout).clamp(0.0, 1.0) : 0.0;

  double _calculateMultiplier() {
    if (comboCount < 5) return 1.0;
    if (comboCount < 10) return 1.5;
    if (comboCount < 20) return 2.0;
    if (comboCount < 30) return 2.5;
    return 3.0;
  }

  void onEnemyDestroyed(Enemy enemy) {
    comboCount++;
    if (comboCount > maxCombo) maxCombo = comboCount;
    comboTimer = comboTimeout;

    final basePoints = enemy.points;
    final bonusPoints = (basePoints * (multiplier - 1)).round();
    gameRef.score += bonusPoints;
    
    // Check for combo achievements
    _checkComboAchievements();
    
    // Check for perfect combo (20+)
    if (comboCount == 20) {
      _tryUnlock(Achievement.perfectCombo);
    }
  }
  
  void onCriticalHit() {
    _criticalHits++;
    if (_criticalHits >= 10) {
      _tryUnlock(Achievement.criticalMaster);
    }
  }
  
  void onChainLightningKill() {
    _chainLightningKills++;
    if (_chainLightningKills >= 5) {
      _tryUnlock(Achievement.chainReaction);
    }
  }
  
  void onPowerUpUsed(PowerUpType type) {
    _usedPowerUpTypes.add(type);
    if (_usedPowerUpTypes.length >= 12) {
      _tryUnlock(Achievement.powerUpConnoisseur);
    }
  }
  
  void _checkComboAchievements() {
    if (comboCount >= 5) _tryUnlock(Achievement.combo5);
    if (comboCount >= 10) _tryUnlock(Achievement.combo10);
    if (comboCount >= 15) _tryUnlock(Achievement.combo15);
  }
  
  Future<void> _tryUnlock(Achievement ach) async {
    final service = AchievementService();
    await service.init();
    final result = await service.tryUnlock(ach);
    if (result != null) {
      // Queue achievement popup
      gameRef.add(ComboPopup(
        title: ach.title,
        description: ach.description,
        icon: ach.icon,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) {
        comboCount = 0;
        comboTimer = 0;
      }
    }
  }

  void reset() {
    comboCount = 0;
    comboTimer = 0;
    _criticalHits = 0;
    _chainLightningKills = 0;
  }

  String get comboText {
    if (comboCount < 5) return '';
    if (comboCount < 10) return '🔥 x1.5';
    if (comboCount < 20) return '🔥🔥 x2.0';
    if (comboCount < 30) return '🔥🔥🔥 x2.5';
    return '🔥🔥🔥🔥 x3.0';
  }

  String get comboEmoji {
    if (comboCount >= 15) return '🔥🔥🔥';
    if (comboCount >= 10) return '🔥🔥';
    if (comboCount >= 5) return '🔥';
    return '⚡';
  }
}

// AchievementPopup import for combo system
class ComboPopup extends PositionComponent {
  final String title;
  final String description;
  final String icon;
  double life = 2.5;

  ComboPopup({
    required this.title,
    required this.description,
    required this.icon,
  }) : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    position = Vector2(200, 20);
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y -= 20 * dt;
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / 2.5).clamp(0.0, 1.0);
    final bgPaint = Paint()..color = Color(0xFF1A1A2E).withAlpha((alpha * 230).round());
    final borderPaint = Paint()
      ..color = Color(0xFFFFD700).withAlpha((alpha * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$icon $title',
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 255).round()),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final descPainter = TextPainter(
      text: TextSpan(
        text: description,
        style: TextStyle(
          color: Colors.white70.withAlpha((alpha * 200).round()),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    descPainter.layout();
    
    final width = textPainter.width.clamp(descPainter.width, 200.0);
    final height = textPainter.height + descPainter.height + 12;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width + 24, height: height + 16),
      Radius.circular(12),
    );
    
    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);
    
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -height / 2));
    descPainter.paint(canvas, Offset(-descPainter.width / 2, -height / 2 + textPainter.height + 4));
  }
}
