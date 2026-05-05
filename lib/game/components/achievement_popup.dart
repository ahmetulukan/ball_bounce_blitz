import 'package:flame/components.dart';
import '../ball_bounce_game.dart';
import '../services/achievement_service.dart';
import '../../services/achievement_service.dart' as svc;

class AchievementPopup extends PositionComponent {
  final String title;
  final String description;
  final String icon;
  final Color color;
  double life = 2.5;
  double _maxLife = 2.5;

  AchievementPopup({
    required this.title,
    required this.description,
    required this.icon,
    this.color = const Color(0xFFFFD700),
  }) : super(
          anchor: Anchor.topCenter,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(200, 20);
  }

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
    
    // Float upward
    position.y -= 20 * dt;
    
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (life / _maxLife).clamp(0.0, 1.0);
    final scale = 1.0 + (1 - life / _maxLife) * 0.2;
    
    final bgPaint = Paint()
      ..color = Color(0xFF1A1A2E).withAlpha((alpha * 230).round());
    
    final borderPaint = Paint()
      ..color = color.withAlpha((alpha * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$icon $title',
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 255).round()),
          fontSize: 14 * scale,
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
          fontSize: 10 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    descPainter.layout();
    
    final width = textPainter.width.clamp(descPainter.width, 200.0);
    final height = textPainter.height + descPainter.height + 12;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: width + 24,
        height: height + 16,
      ),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);
    
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -height / 2));
    descPainter.paint(canvas, Offset(-descPainter.width / 2, -height / 2 + textPainter.height + 4));
  }
}