import 'dart:ui';
import 'package:flame/components.dart';
import '../game/game.dart';

class ScreenFlash extends Component with HasGameReference<BallBounceBlitzGame> {
  double elapsed = 0;
  double duration;
  Color color;

  ScreenFlash({this.color = const Color(0xFFFFFFFF), this.duration = 0.3});

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = elapsed / duration;
    final alpha = (1 - progress).clamp(0.0, 1.0) * 0.5;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y),
      Paint()..color = Color.fromARGB((alpha * 255).toInt(), color.value >> 16 & 0xFF, color.value >> 8 & 0xFF, color.value & 0xFF),
    );
  }
}
