import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../ball_bounce_game.dart';

class ScorePopup extends PositionComponent {
  final int score;
  final Color color;
  double life = 1.0;
  final double maxLife = 1.0;
  double _vy = -60;

  ScorePopup({
    required Vector2 position,
    required this.score,
    this.color = const Color(0xFFFFD700),
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    position.y += _vy * dt;
    _vy += 30 * dt;
    
    if (life <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / maxLife).clamp(0.0, 1.0);
    final scale = 1.0 + (1 - life / maxLife) * 0.3;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$score',
        style: TextStyle(
          color: color.withAlpha((alpha * 255).round()),
          fontSize: 16 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

class ComboDisplay extends PositionComponent {
  late BallBounceGame gameRef;
  double life = 0;
  final double maxDisplayTime = 2.0;
  double _phase = 0;

  ComboDisplay() : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(200, 80);
  }

  void show() {
    life = maxDisplayTime;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 8;
    if (life > 0) {
      life -= dt;
      if (life <= 0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (life <= 0) return;
    
    final alpha = (life / maxDisplayTime).clamp(0.0, 1.0);
    final combo = gameRef.comboSystem.comboCount;
    if (combo < 3) return;
    
    final scale = 1.0 + sin(_phase) * 0.05;
    final color = _getComboColor(combo);
    
    final bgPaint = Paint()
      ..color = const Color(0xFF000000).withAlpha((alpha * 180).round());
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🔥 x$combo',
        style: TextStyle(
          color: color.withAlpha((alpha * 255).round()),
          fontSize: 24 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final multiplier = gameRef.comboSystem.multiplier;
    final multTextPainter = TextPainter(
      text: TextSpan(
        text: '×${multiplier.toStringAsFixed(1)}',
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 200).round()),
          fontSize: 14 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    multTextPainter.layout();
    
    final width = textPainter.width + 20;
    final height = textPainter.height + multTextPainter.height + 16;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(rect, bgPaint);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -height / 2));
    multTextPainter.paint(canvas, Offset(-multTextPainter.width / 2, -height / 2 + textPainter.height + 2));
  }

  Color _getComboColor(int combo) {
    if (combo >= 20) return const Color(0xFFFF5722);
    if (combo >= 10) return const Color(0xFFFFEB3B);
    if (combo >= 5) return const Color(0xFF03A9F4);
    return Colors.white;
  }
}

class ScoreSystem extends Component {
  late BallBounceGame gameRef;
  int highScore = 0;

  void setGame(BallBounceGame game) {
    gameRef = game;
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    // High score persistence handled in game state
  }

  void spawnScorePopup(int score, Vector2 position) {
    final color = score >= 50 
        ? const Color(0xFFFF5722) 
        : score >= 20 
            ? const Color(0xFFFFEB3B) 
            : const Color(0xFFFFFFFF);
    gameRef.add(ScorePopup(position: position.clone(), score: score, color: color));
  }

  void onGameOver(int finalScore) {
    if (finalScore > highScore) {
      highScore = finalScore;
    }
  }

  int getHighScore() => highScore;

  void updateHighScore(int score) {
    if (score > highScore) {
      highScore = score;
    }
  }
}