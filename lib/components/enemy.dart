import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../game/game.dart';
import '../../services/audio_manager.dart';

enum EnemyType { normal, fast, tough, big }

class Enemy extends PositionComponent with HasGameReference<BallBounceBlitzGame> {
  double speed;
  static const double baseWidth = 30;
  static const double baseHeight = 30;
  double width = baseWidth;
  double height = baseHeight;
  int hits = 1;
  final EnemyType type;
  final dynamic gameScene;

  Enemy({required double x, required double y, required this.speed, this.gameScene, this.type = EnemyType.normal})
      : super(anchor: Anchor.center) {
    position = Vector2(x, y);
    _applyType();
  }

  void _applyType() {
    switch (type) {
      case EnemyType.normal:
        width = 30; height = 30; hits = 1; speed = speed;
        break;
      case EnemyType.fast:
        width = 22; height = 22; hits = 1; speed = speed * 1.6;
        break;
      case EnemyType.tough:
        width = 35; height = 35; hits = 3; speed = speed * 0.7;
        break;
      case EnemyType.big:
        width = 50; height = 50; hits = 2; speed = speed * 0.5;
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameRef.size.y + 60) removeFromParent();
  }

  void takeHit(dynamic scene) {
    hits--;
    if (hits <= 0) {
      AudioManager.playScore();
      final pts = (type == EnemyType.big ? 50 : type == EnemyType.tough ? 40 : type == EnemyType.fast ? 20 : 25);
      scene?.onScore(pts);
      scene?.shake();
      removeFromParent();
    } else {
      // Flash effect on partial hit
      scene?.onPartialHit();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = typeColor();
    canvas.drawRect(Rect.fromLTWH(-width / 2, -height / 2, width, height), paint);

    if (type == EnemyType.tough) {
      // Draw HP pips
      final hpPaint = Paint()..color = Colors.white;
      for (int i = 0; i < hits; i++) {
        canvas.drawCircle(Offset(-width / 2 + 8 + i * 10, -height / 2 - 6), 3, hpPaint);
      }
    }

    final xp = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-width / 2 + 5, -height / 2 + 5), Offset(width / 2 - 5, height / 2 - 5), xp);
    canvas.drawLine(Offset(width / 2 - 5, -height / 2 + 5), Offset(-width / 2 + 5, height / 2 - 5), xp);
  }

  Color typeColor() {
    switch (type) {
      case EnemyType.normal: return const Color(0xFFE91E63);
      case EnemyType.fast: return const Color(0xFFFF5722);
      case EnemyType.tough: return const Color(0xFF3F51B5);
      case EnemyType.big: return const Color(0xFF9C27B0);
    }
  }
}
